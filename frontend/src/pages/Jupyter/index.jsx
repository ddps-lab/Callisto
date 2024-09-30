import { Badge, Button, Drawer, Dropdown, Flex, Modal, Table } from 'antd';
import { PlusOutlined, SyncOutlined } from '@ant-design/icons';
import { useMessageApi, useUserStore } from '../../store/zustand.js';
import { useEffect, useState } from 'react';
import JupyterModal from './JupyterModal.jsx';
import {
  deleteJupyter,
  getJupyters,
  updateJupyter
} from '../../apis/db/index.js';

export default function Jupyter() {
  const { messageApi } = useMessageApi();
  const { idToken } = useUserStore();
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedRowKeys, setSelectedRowKeys] = useState([]);
  const [selected, setSelected] = useState(null);
  const [isUpdate, setIsUpdate] = useState(false);
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);

  const fetchData = async () => {
    setFetching(true);
    const jupyters = await getJupyters(idToken);
    if (jupyters.length !== 0)
      setData(
        jupyters.map((jupyter) => ({
          ...jupyter,
          key: `${jupyter.sub}@${jupyter.created_at}`
        }))
      );
    setFetching(false);
  };

  const TABLE_COLUMNS = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      ellipsis: true,
      render: (item) => <Badge status={'default'} text={item} />
    },
    {
      title: 'Endpoint URL',
      dataIndex: 'endpoint_url',
      key: 'endpoint_url',
      ellipsis: true,
      render: (url) => <a>{url}</a>
    },
    {
      title: 'CPU (cores)',
      dataIndex: 'cpu',
      key: 'cpu',
      ellipsis: true
    },
    {
      title: 'Memory (GB)',
      dataIndex: 'memory',
      key: 'memory',
      ellipsis: true
    },

    {
      title: 'Disk (GB)',
      dataIndex: 'disk',
      key: 'disk',
      ellipsis: true
    }
  ];

  useEffect(() => {
    fetchData();
  }, []);

  console.log(selected);

  return (
    <>
      <Drawer
        title="Delete Confirmation"
        onClose={() => {
          setIsConfirmOpen(false);
        }}
        open={isConfirmOpen}
      >
        <p>
          Are you sure you want to delete the Jupyter instance named{' '}
          <b>{selected?.name}?</b>
        </p>
        <p>This action cannot be undone.</p>
        <Flex vertical={true} gap={10}>
          <Button>Cancel</Button>
          <Button
            type="primary"
            loading={fetching}
            danger
            onClick={async () => {
              setFetching(true);
              await deleteJupyter(idToken, selected.key)
                .then(() => {
                  messageApi.success(
                    'The Jupyter instance has been successfully deleted.'
                  );
                })
                .catch((e) => {
                  console.log(e);
                  messageApi.error(
                    'An error occurred while deleting the Jupyter instance. Please try again.'
                  );
                });
              await fetchData();
              setSelected(null);
              setFetching(false);
              setIsConfirmOpen(false);
            }}
          >
            Delete
          </Button>
        </Flex>
      </Drawer>
      <Flex vertical style={{ padding: '20px' }}>
        <Flex
          style={{ width: '100%', marginBottom: '20px' }}
          justify={'space-between'}
          align={'center'}
        >
          <h2>Jupyter</h2>
          <Flex gap={10}>
            <Button onClick={fetchData}>
              <SyncOutlined />
            </Button>
            {/*<Input addonBefore={<SearchOutlined />} />*/}
            <Dropdown
              disabled={!selected || fetching}
              menu={{
                items: [
                  {
                    label: 'Edit',
                    key: 'edit',
                    onClick: () => {
                      setIsUpdate(true);
                      setIsModalOpen(true);
                    }
                  },
                  {
                    label: 'Start',
                    key: 'start',
                    onClick: async () => {
                      setFetching(true);
                      await updateJupyter(idToken, {
                        uid: selected.key,
                        status: 'start'
                      })
                        .then(() => {
                          setSelectedRowKeys(null);
                          setSelected(null);
                          fetchData();
                          messageApi.success(
                            'The Jupyter instance has been successfully started.'
                          );
                        })
                        .catch((e) => {
                          console.log(e);
                          messageApi.error(
                            'An error occurred while starting the Jupyter instance. Please try again.'
                          );
                        });
                      setFetching(false);
                    }
                  },
                  {
                    label: 'Delete',
                    key: 'delete',
                    danger: true,
                    onClick: () => setIsConfirmOpen(true)
                  }
                ]
              }}
            >
              <Button>Actions</Button>
            </Dropdown>
            <Button
              loading={fetching}
              type={'primary'}
              onClick={() => {
                setIsModalOpen(true);
              }}
            >
              <PlusOutlined />
              Add New
            </Button>
          </Flex>
        </Flex>
        <Table
          loading={fetching}
          columns={TABLE_COLUMNS}
          rowSelection={{
            selectedRowKeys,
            type: 'radio',
            onChange: (selectedRowKeys, selectedRows) => {
              setSelectedRowKeys(selectedRowKeys);
              setSelected(selectedRows.pop());
            }
          }}
          dataSource={data}
        />
      </Flex>
      <JupyterModal
        isUpdate={isUpdate}
        jupyter={isUpdate ? selected : null}
        isOpen={isModalOpen}
        idToken={idToken}
        onClose={() => {
          setIsModalOpen(false);
          setIsUpdate(false);
          setSelected(null);
          setSelectedRowKeys([]);
          fetchData();
        }}
      />
      <Modal></Modal>
    </>
  );
}
