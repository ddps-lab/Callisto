import './App.css';

import { useEffect } from 'react';
import { useMessageApi } from './store/zustand.js';

import { ConfigProvider, message } from 'antd';
import { StyleProvider } from '@ant-design/cssinjs';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext.jsx';

import DefaultLayout from './layout.jsx';
import Login from './pages/forms/Login/index.jsx';
import Signup from './pages/forms/Signup/index.jsx';
import Confirm from './pages/forms/Confirm/index.jsx';
import Overview from './pages/Overview/index.jsx';
import Jupyter from './pages/Jupyter/index.jsx';
import Admin from './pages/Admin/index.jsx';

const settings = {
  components: {
    Form: {
      itemMarginBottom: 8
    },
    Layout: {
      siderBg: '#fff',
      triggerBg: '#fff',
      triggerColor: '#000',
      headerPadding: '0px 24px'
    }
  }
};

function App() {
  const [messageApi, contextHolder] = message.useMessage();
  const { setMessageApi } = useMessageApi();
  useEffect(() => {
    setMessageApi(messageApi);
  }, [messageApi, setMessageApi]);

  return (
    <BrowserRouter>
      <StyleProvider layer>
        <ConfigProvider theme={settings} componentSize="middle">
          {contextHolder}
          <AuthProvider>
            <Routes>
              <Route index element={<Login />} />
              <Route path={'/sign-up'} element={<Signup />} />
              <Route path={'/confirm'} element={<Confirm />} />
              <Route element={<DefaultLayout />}>
                <Route path={'/overview'} element={<Overview />} />
                <Route path={'/jupyter'} element={<Jupyter />} />
                <Route path={'/admin'} element={<Admin />} />
              </Route>
            </Routes>
          </AuthProvider>
        </ConfigProvider>
      </StyleProvider>
    </BrowserRouter>
  );
}

export default App;
