import { Badge, Button, Dropdown, Flex, Input, Table } from 'antd';
import { PlusOutlined, SearchOutlined, SyncOutlined } from '@ant-design/icons';
import { useMessageApi, useUserStore } from '../../store/zustand.js';
import { useEffect, useState } from 'react';
import axios from 'axios';

export default function Jupyter() {
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(true);
  const { messageApi } = useMessageApi();
  const { idToken } = useUserStore();

  const fetchData = async () => {
    setFetching(true);
    const jupyters = await axios.get(
      `${import.meta.env.VITE_DB_API_URL}/jupyter`,
      {
        headers: {
          'id-token': idToken
        }
      }
    );
    if (jupyters.data.length !== 0)
      setData(
        jupyters.data.map((jupyter) => ({
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

  return (
    <Flex vertical style={{ padding: '20px' }}>
      <Flex
        style={{ width: '100%', marginBottom: '20px' }}
        justify={'space-between'}
        align={'center'}
      >
        <h2>Jupyter</h2>
        <Flex gap={10}>
          <Button>
            <SyncOutlined />
          </Button>
          <Input addonBefore={<SearchOutlined />} />
          <Dropdown
            menu={{
              items: [
                {
                  label: 'Delete',
                  key: 'delete',
                  danger: true
                }
              ]
            }}
          >
            <Button>Actions</Button>
          </Dropdown>
          <Button type={'primary'} onClick={() => {}}>
            <PlusOutlined />
            Add New
          </Button>
        </Flex>
      </Flex>
      <Table
        loading={fetching}
        columns={TABLE_COLUMNS}
        rowSelection={{
          type: 'radio'
        }}
        dataSource={data}
      />
    </Flex>
  );
}
