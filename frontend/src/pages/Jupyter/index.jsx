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
  Empty,
  Checkbox
} from 'antd';
import { PlusOutlined, SyncOutlined } from '@ant-design/icons';
import { useMessageApi } from '../../store/zustand.js';
import { useEffect, useState } from 'react';
import JupyterModal from './JupyterModal.jsx';
import {
  deleteJupyter,
  getJupyters,
  updateJupyter
} from '../../apis/db/index.js';

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

const AUTO_REFRESH_INTERVAL = 15;

const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1);

export default function Jupyter() {
  const { messageApi } = useMessageApi();
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedRowKeys, setSelectedRowKeys] = useState([]);
  const [selected, setSelected] = useState(null);
  const [isUpdate, setIsUpdate] = useState(false);
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(false);
  const [refreshCountdown, setRefreshCountdown] = useState(
    AUTO_REFRESH_INTERVAL
  );

  const fetchData = async () => {
    setFetching(true);
    const jupyters = await getJupyters();
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
      ),
      width: 200
    },
    {
      title: 'CPU (cores)',
      dataIndex: 'cpu',
      key: 'cpu',
      ellipsis: true,
      width: 120
    },
    {
      title: 'Memory (GB)',
      dataIndex: 'memory',
      key: 'memory',
      ellipsis: true,
      width: 120
    },
    {
      title: 'Disk (GB)',
      dataIndex: 'disk',
      key: 'disk',
      ellipsis: true,
      width: 120
    },
    {
      title: 'Created At',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (item) => <span>{new Date(item).toLocaleString()}</span>,
      sorter: (a, b) => new Date(a.created_at) - new Date(b.created_at),
      width: 190
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
      ),
      width: 120
    }
  ];

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    let interval;
    if (autoRefresh) {
      setRefreshCountdown(AUTO_REFRESH_INTERVAL);
      interval = setInterval(() => {
        setRefreshCountdown((prev) => {
          if (prev === 1) {
            fetchData();
            return AUTO_REFRESH_INTERVAL;
          }
          return prev - 1;
        });
      }, AUTO_REFRESH_INTERVAL * 100);
    } else {
      setRefreshCountdown(AUTO_REFRESH_INTERVAL);
    }
    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [autoRefresh]);

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
              const jupyter = await deleteJupyter(selected.key);
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
      <Flex vertical>
        <Flex
          style={{ width: '100%', marginBottom: '20px' }}
          justify={'space-between'}
          align={'center'}
        >
          <h2 className="text-4xl">Jupyter</h2>
          <Flex gap={10} align="center">
            <Checkbox
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
            >
              Auto Refresh
            </Checkbox>
            <Button onClick={fetchData} disabled={autoRefresh}>
              <SyncOutlined />
              <div className={autoRefresh ? '' : 'hidden'}>
                {autoRefresh ? <span>{refreshCountdown}s</span> : <></>}
              </div>
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
                    },
                    disabled: true
                  },
                  {
                    label: 'Start',
                    key: 'start',
                    onClick: async () => {
                      setFetching(true);
                      const jupyter = await updateJupyter({
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
