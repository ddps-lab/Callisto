import { LockOutlined, UserOutlined } from '@ant-design/icons';
import { Button, Checkbox, ConfigProvider, Form, Input } from 'antd';
import { FormLayout } from '../styles.jsx';
import { useNavigate } from 'react-router-dom';
import { cognitoSignIn } from '../../../apis/cognito/index.js';
import {
  useChallengeStore,
  useConfirmStore,
  useMessageApi,
  useUserStore
} from '../../../store/zustand.js';
import { COGNITO_SIGN_IN_STATUS } from '../../../store/constant.js';

export default function Login() {
  const navigate = useNavigate();

  const userStore = useUserStore();
  const challengeStore = useChallengeStore();
  const confirmStore = useConfirmStore();
  const { messageApi } = useMessageApi();

  const onFinish = async (values) => {
    const result = await cognitoSignIn(values);
    if (result.status === COGNITO_SIGN_IN_STATUS.SUCCESS) {
      userStore.setRefreshToken(result.refreshToken);
      userStore.setIdToken(result.idToken);
      userStore.setAccessToken(result.accessToken);
      navigate('/overview');
    } else if (result.status === COGNITO_SIGN_IN_STATUS.NOT_AUTHORIZED) {
      messageApi.error(
        'The account or password is invalid. Please check again.'
      );
    } else if (result.status === COGNITO_SIGN_IN_STATUS.NEED_CHALLENGE) {
      challengeStore.setChallenge(result.session, result.challengeName);
    } else if (result.status === COGNITO_SIGN_IN_STATUS.NEED_CONFIRM) {
      confirmStore.setEmail(values.email);
      navigate('/confirm');
    }
  };
  return (
    <ConfigProvider componentSize="large">
      <FormLayout onFinish={onFinish}>
        <Form.Item
          name="email"
          rules={[
            {
              required: true,
              message: 'Please input your email!'
            },
            {
              type: 'email',
              message: 'Please input a valid email!'
            }
          ]}
        >
          <Input prefix={<UserOutlined />} placeholder="Email" />
        </Form.Item>
        <Form.Item
          name="password"
          rules={[
            {
              required: true,
              message: 'Please input your password!'
            }
          ]}
        >
          <Input.Password prefix={<LockOutlined />} placeholder="Password" />
        </Form.Item>
        <Form.Item name="remember" valuePropName="checked">
          <Checkbox>Remember me</Checkbox>
        </Form.Item>
        <Form.Item>
          <Button type="primary" htmlType="submit" className="w-full">
            Login
          </Button>
        </Form.Item>
        <Form.Item>
          <a onClick={() => navigate('/sign-up', { replace: true })} className='text-brand-500'>
            Don&apos;t have an account? Sign-up
          </a>
        </Form.Item>
      </FormLayout>
    </ConfigProvider>
  );
}
