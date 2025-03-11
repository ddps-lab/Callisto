import {
  Badge,
  Button,
  ConfigProvider,
  Drawer,
  Dropdown,
  Flex,
  Modal,
  Table,
  Tooltip,
  Empty
} from 'antd';
import { PlusOutlined, SyncOutlined } from '@ant-design/icons';
import { useMessageApi, useUserStore } from '../../store/zustand.js';
import { useEffect, useState } from 'react';
import JupyterModal from './JupyterModal.jsx';
import {
  deleteJupyter,
  getJupyters,
  updateJupyter
} from '../../apis/db/index.js';
import { isNAToken } from '../../utils/index.js';
import { cognitoRefreshAuth } from '../../apis/cognito/index.js';
import { COGNITO_SIGN_IN_STATUS } from '../../store/constant.js';

const BADGE_STATUS = {
  pending: 'default',
  running: 'success',
  stopped: 'error',
  migrating: 'processing'
};

const TOOLTIP_MESSAGE = {
  pending: 'Please wait while the Jupyter instance is being created.',
  running: '',
  stopped: 'Please start the Jupyter instance to access.',
  migrating: 'Please wait while the Jupyter instance is being migrated.'
};

const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1);

export default function Jupyter() {
  const { messageApi } = useMessageApi();
  const { idToken, setAccessToken, setIdToken } = useUserStore();
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
      render: (item) => (
        <Badge status={BADGE_STATUS[item]} text={capitalize(item)} />
      )
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
    },
    {
      title: 'Access',
      dataIndex: 'endpoint_url',
      key: 'endpoint_url',
      ellipsis: true,
      render: (url, record) => (
        <div>
          <ConfigProvider
            theme={{
              components: {
                Button: { paddingBlock: 0, paddingInline: 0 }
              }
            }}
          >
            <Tooltip
              title={TOOLTIP_MESSAGE[record.status]}
              placement="right"
              arrow={true}
            >
              <Button
                type="link"
                href={url}
                target="_blank"
                disabled={record.status !== 'running'}
              >
                <b>Open Link</b>
              </Button>
            </Tooltip>
          </ConfigProvider>
        </div>
      )
    }
  ];

  const refresh = async (refreshToken) => {
    const res = await cognitoRefreshAuth(refreshToken);
    if (res?.status === COGNITO_SIGN_IN_STATUS.SUCCESS) {
      setAccessToken(res.accessToken);
      setIdToken(res.idToken);
    }
  };

  useEffect(() => {
    if (isNAToken(idToken)) {
      const refreshToken = localStorage.getItem('refreshToken');
      if (refreshToken) {
        refresh(refreshToken).then(() => {
          fetchData();
        });
      } else location.href = '/';
    } else fetchData();
  }, []);

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
              const jupyter = await deleteJupyter(idToken, selected.key);
              if (jupyter) {
                messageApi.success(
                  'The Jupyter instance has been successfully deleted.'
                );
              } else {
                messageApi.error(
                  'An error occurred while deleting the Jupyter instance. Please try again.'
                );
              }
              await fetchData();
              setSelected(null);
              setSelectedRowKeys(null);
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
                      const jupyter = await updateJupyter(idToken, {
                        uid: selected.key,
                        status: 'start'
                      });

                      if (jupyter) {
                        setSelected(null);
                        fetchData();
                        messageApi.success(
                          'The Jupyter instance has been successfully started.'
                        );
                      } else {
                        messageApi.error(
                          'An error occurred while starting the Jupyter instance. Please try again.'
                        );
                      }
                      setSelected(null);
                      setSelectedRowKeys(null);
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
          locale={{
            emptyText: (
              <Empty
                description="No Jupyter instances found."
                image={Empty.PRESENTED_IMAGE_SIMPLE}
              />
            )
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
