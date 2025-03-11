import { Layout, Menu } from 'antd';
import { useNavigate } from 'react-router-dom';
import { DashboardOutlined, ExperimentOutlined } from '@ant-design/icons';

export default function SideBar() {
  const navigate = useNavigate();

  const items = [
    {
      key: 'overview',
      icon: <DashboardOutlined />,
      label: 'Overview'
    },
    {
      key: 'jupyter',
      icon: <ExperimentOutlined />,
      label: 'Jupyter'
    }
  ];

  const handleMenuClick = (e) => {
    navigate('/' + e.key);
  };

  return (
    <Layout.Sider collapsible>
      <Menu
        mode="inline"
        defaultSelectedKeys={['overview']}
        selectedKeys={[location.pathname.split('/').pop()]}
        style={{
          display: 'flex',
          flexDirection: 'column',
          height: '100%',
          border: 'none'
        }}
        items={items}
        onClick={handleMenuClick}
      />
    </Layout.Sider>
  );
}
