import { LogoutOutlined, QuestionCircleOutlined } from '@ant-design/icons';
import { Button, Layout } from 'antd';
import { useNavigate } from 'react-router-dom';
import { useUserStore } from '../../store/zustand.js';

export default function Header() {
  const navigate = useNavigate();
  const { userInfo, logout } = useUserStore();

  return (
    <Layout.Header className="flex items-center bg-slate-800 text-white px-6 py-3">
      <div
        className="flex items-center text-2xl font-normal cursor-pointer tracking-[.20em] uppercase"
        onClick={() => navigate('/overview')}
      >
        Callisto
      </div>
      <div className="flex items-center ml-auto gap-4">
        <div className="flex items-center gap-4">
          <Button
            size="small"
            type="text"
            icon={<QuestionCircleOutlined />}
            className="text-white"
          />
          <Button
            size="small"
            type="text"
            icon={<LogoutOutlined />}
            className="text-white"
            onClick={() => {
              logout();
              localStorage.clear();
              navigate('/');
            }}
          />
        </div>
        <div className="ml-3 text-white text-lg">
          <span className="font-bold">{userInfo.nickname}</span>
        </div>
      </div>
    </Layout.Header>
  );
}
