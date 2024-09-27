import { Layout } from 'antd';
import SideBar from './components/Sidebar/index.jsx';
import Header from './components/Header/index.jsx';
import { Outlet } from 'react-router-dom';

export default function DefaultLayout() {
  return (
    <Layout>
      <Header />
      <Layout>
        <SideBar />
        <Layout.Content
          style={{
            height: 'calc(100vh - 64px)',
            padding: '20px'
          }}
        >
          <div style={{ background: '#fff' }}>
            <Outlet />
          </div>
        </Layout.Content>
      </Layout>
    </Layout>
  );
}
