import './App.css';
import Login from './pages/forms/Login/index.jsx';
import { ConfigProvider, message } from 'antd';
import { StyleProvider } from '@ant-design/cssinjs';
import Signup from './pages/forms/Signup/index.jsx';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import Confirm from './pages/forms/Confirm/index.jsx';
import { useEffect } from 'react';
import { useMessageApi } from './store/zustand.js';
import Overview from './pages/Overview/index.jsx';
import Jupyter from './pages/Jupyter/index.jsx';
import DefaultLayout from './layout.jsx';

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
          <Routes>
            <Route index element={<Login />} />
            <Route path={'/sign-up'} element={<Signup />} />
            <Route path={'/confirm'} element={<Confirm />} />
            <Route element={<DefaultLayout />}>
              <Route path={'/overview'} element={<Overview />} />
              <Route path={'/jupyter'} element={<Jupyter />} />
              <Route path={'/menu3'} element={<></>} />
              <Route path={'/menu4'} element={<></>} />
            </Route>
          </Routes>
        </ConfigProvider>
      </StyleProvider>
    </BrowserRouter>
  );
}

export default App;
