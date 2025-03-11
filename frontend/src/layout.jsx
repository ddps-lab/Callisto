import { Layout } from 'antd';
import SideBar from './components/Sidebar/index.jsx';
import Header from './components/Header/index.jsx';
import Footer from './components/Footer/index.jsx';
import { Outlet } from 'react-router-dom';

export default function DefaultLayout() {
  return (
    <Layout>
      <Header />
      <Layout className="h-full">
        <SideBar />
        <Layout.Content className="overflow-y-auto h-full box-border">
          <div className="h-full box-border p-8 min-h-[calc(100vh-64px)]">
            <Outlet />
          </div>
          <Footer />
        </Layout.Content>
      </Layout>
    </Layout>
  );
}
