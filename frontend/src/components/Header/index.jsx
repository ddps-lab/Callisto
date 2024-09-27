import { QuestionCircleOutlined, SettingOutlined } from '@ant-design/icons';
import { Button, Layout } from 'antd';
import styled from 'styled-components';
import { useNavigate } from 'react-router-dom';
import { useUserStore } from '../../store/zustand.js';

const Logo = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  color: #fff;
  font-size: 24px;
  font-weight: 900;
  gap: 8px;
  letter-spacing: -1px;
  cursor: pointer;

  > img {
    -webkit-user-drag: none;
    user-drag: none;
  }
`;

const Menu = styled.div`
  display: flex;
  align-items: center;
  margin-left: auto;
  gap: 10px;
`;

const ButtonGroup = styled.div`
  display: flex;
  align-items: center;
  gap: 15px;
  .outline-white {
    > svg {
      fill: #fff;
    }
  }
`;

const User = styled.div`
  margin-left: 10px;
  color: white;
  font-size: 16px;
  > .user-name {
    font-weight: bold;
  }
`;

export default function Header(props) {
  const navigate = useNavigate();
  const { userInfo } = useUserStore();
  return (
    <Layout.Header style={{ display: 'flex' }}>
      <Logo
        onClick={() => {
          navigate('/overview');
        }}
      >
        Callisto
      </Logo>
      <Menu>
        <ButtonGroup>
          <Button
            size={'small'}
            type={'text'}
            icon={<QuestionCircleOutlined className={'outline-white'} />}
          />
          <Button
            size={'small'}
            type={'text'}
            icon={<SettingOutlined className={'outline-white'} />}
          />
        </ButtonGroup>
        <User>
          <span className={'user-name'}>{userInfo.nickname}</span>
        </User>
      </Menu>
    </Layout.Header>
  );
}
