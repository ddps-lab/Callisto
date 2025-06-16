import { Button, Layout } from 'antd';
import { useNavigate } from 'react-router-dom';
import { useUserStore } from '../../store/zustand.js';
import { ArrowRightStartOnRectangleIcon, QuestionMarkCircleIcon } from '@heroicons/react/24/outline';

export default function Header() {
  const navigate = useNavigate();
  const { userInfo, logout } = useUserStore();

  return (
    <Layout.Header className="flex items-center bg-brand-600 text-white px-6 py-3">
      <div
        className="flex items-center text-2xl font-normal cursor-pointer tracking-[.20em] uppercase"
        onClick={() => navigate('/overview')}
      >
        <svg xmlns="http://www.w3.org/2000/svg" id="Layer_1" data-name="Layer 1" viewBox="0 0 259.33 54.73" className='fill-white h-8'>
          <path d="M231.97 54.73c-15.09 0-27.36-12.28-27.36-27.36S216.88 0 231.97 0s27.36 12.28 27.36 27.36-12.28 27.36-27.36 27.36Zm0-48.61c-11.71 0-21.24 9.53-21.24 21.24s9.53 21.24 21.24 21.24 21.24-9.53 21.24-21.24-9.53-21.24-21.24-21.24Z"/>
          <path d="M231.69 40.73c-7.37 0-13.37-6-13.37-13.37s6-13.37 13.37-13.37 13.37 6 13.37 13.37-6 13.37-13.37 13.37ZM44.96 12.99 34.45 41.71h5.08l2.75-7.69h9.95l2.71 7.69h5.12L49.55 12.99h-4.59Zm5.7 16.62h-6.85l3.42-9.65 3.43 9.65ZM74.54 12.99h-4.83v28.72H87.2v-4.46H74.54V12.99zM102.82 12.99h-4.83v28.72h17.49v-4.46h-12.66V12.99zM126.28 12.99h4.83v28.72h-4.83zM155.18 25.34l-2.73-.76c-3.27-.83-4.73-1.99-4.73-3.75 0-2.25 2.12-3.76 5.27-3.76s5.06 1.37 5.31 3.58l.07.64h4.71l-.03-.75c-.17-4.59-4.35-7.93-9.95-7.93S143 16.13 143 20.98c0 3.75 2.51 6.38 7.47 7.82l3.34.9c3.08.89 4.87 1.8 4.87 3.79 0 2.46-2.41 4.18-5.87 4.18-2.55 0-5.37-1.01-5.65-3.83l-.06-.65h-4.89l.05.77c.33 5.01 4.48 8.25 10.55 8.25s10.63-3.47 10.63-8.63c0-6.11-6.22-7.71-8.25-8.23ZM173.05 12.99v4.46h8.59v24.26h4.87V17.45h8.55v-4.46h-22.01zM14.72 17.21c3.77 0 7.21 2.08 8.97 5.43l.2.38h4.91l-.38-.98c-2.19-5.62-7.7-9.4-13.71-9.4C6.6 12.63 0 19.24 0 27.35s6.6 14.72 14.72 14.72c6.01 0 11.52-3.78 13.71-9.4l.38-.98H23.9l-.2.38c-1.77 3.35-5.21 5.43-8.97 5.43-5.59 0-10.15-4.55-10.15-10.14s4.55-10.15 10.15-10.15Z"/>
        </svg>
      </div>
      <div className="flex items-center ml-auto gap-4">
        <div className="flex items-center gap-4">
          <Button
            size="small"
            type="text"
            icon={<QuestionMarkCircleIcon className='w-5 h-5 outline-white hover:outline-white/50' />}
            className="text-white"
          />
          <Button
            size="small"
            type="text"
            icon={<ArrowRightStartOnRectangleIcon className='w-5 h-5 outline-white hover:outline-white/50' />}
            className="text-white"
            onClick={() => {
              logout();
              localStorage.clear();
              navigate('/');
            }}
          />
        </div>
        <div className="ml-3 text-white text-lg">
          <span className="font-bold">{userInfo.username}</span>
        </div>
      </div>
    </Layout.Header>
  );
}
