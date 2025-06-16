import { Layout, Menu } from 'antd';
import { useNavigate } from 'react-router-dom';
import { useUserStore } from '../../store/zustand.js';
import { CodeBracketSquareIcon, HomeIcon, Cog6ToothIcon } from '@heroicons/react/24/outline';

export default function SideBar() {
  const navigate = useNavigate();
  const { userInfo } = useUserStore();

  const items = [
    {
      key: 'overview',
      icon: <HomeIcon className='w-5 h-5' />,
      label: 'Overview'
    },
    {
      key: 'jupyter',
      icon: <CodeBracketSquareIcon className='w-5 h-5' />,
      label: 'Jupyter'
    },
    ...(userInfo.profile === 'admin'
      ? [
          {
            key: 'admin',
            icon: <Cog6ToothIcon className='w-5 h-5' />,
            label: 'Admin'
          }
        ]
      : [])
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
          border: 'none',
          padding: '0px'
        }}
        className=''
        items={items}
        onClick={handleMenuClick}
      />
    </Layout.Sider>
  );
}
