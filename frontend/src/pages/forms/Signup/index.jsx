import { FormLayout } from '../styles.jsx';
import { Button, Form, Input, Space } from 'antd';
import { LockOutlined, SmileOutlined, UserOutlined } from '@ant-design/icons';
import {
  COGNITO_SIGN_UP_STATUS,
  PASSWORD_REGEX
} from '../../../store/constant.js';
import { useNavigate } from 'react-router-dom';
import { cognitoSignUp } from '../../../apis/cognito/index.js';
import { useConfirmStore, useMessageApi } from '../../../store/zustand.js';

export default function Signup() {
  const navigate = useNavigate();
  const { setEmail } = useConfirmStore();
  const { messageApi } = useMessageApi();

  const onFinish = async (values) => {
    const result = await cognitoSignUp(values);
    if (result.status === COGNITO_SIGN_UP_STATUS.SUCCESS) {
      setEmail(values.email);
      navigate('/confirm');
    } else if (result.status === COGNITO_SIGN_UP_STATUS.USERNAME_EXISTS) {
      messageApi.error(
        'This account already exists. Please try signing up with a different account.'
      );
    }
  };
  return (
    <FormLayout onFinish={onFinish}>
      <Form.Item
        style={{
          marginBottom: 0
        }}
      >
        <Space.Compact>
          <Form.Item
            name="firstname"
            rules={[
              {
                required: true,
                message: 'Please input your name!'
              }
            ]}
          >
            <Input placeholder="First Name" />
          </Form.Item>
          <Form.Item
            name="familyName"
            rules={[
              {
                required: true,
                message: 'Please input your Family name!'
              }
            ]}
          >
            <Input placeholder="Family name" />
          </Form.Item>
        </Space.Compact>
      </Form.Item>

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
        name="nickname"
        rules={[
          {
            required: true,
            message: 'Please input nickname!'
          }
        ]}
      >
        <Input prefix={<SmileOutlined />} placeholder="Nickname" />
      </Form.Item>
      <Form.Item
        name="password"
        rules={[
          {
            required: true,
            message: 'Please input your password!'
          },
          {
            pattern: PASSWORD_REGEX,
            message:
              'Least 8 characters, including uppercase and lowercase letters, numbers, and special characters.'
          }
        ]}
      >
        <Input.Password prefix={<LockOutlined />} placeholder="Password" />
      </Form.Item>
      <Form.Item
        name="confirm-password"
        rules={[
          {
            required: true,
            message: 'Please confirm your password!'
          },
          ({ getFieldValue }) => ({
            validator(_, value) {
              if (!value || getFieldValue('password') === value) {
                return Promise.resolve();
              }
              return Promise.reject(
                new Error('The password that you entered do not match!')
              );
            }
          })
        ]}
        style={{
          marginBottom: '30px'
        }}
      >
        <Input.Password
          prefix={<LockOutlined />}
          placeholder="Confirm Password"
        />
      </Form.Item>
      <Form.Item>
        <Button
          type="default"
          style={{
            display: 'inline-block'
          }}
          onClick={() => navigate('/', { replace: true })}
        >
          Back to Login
        </Button>
        <Button
          type="primary"
          style={{
            display: 'inline-block',
            marginLeft: '8px'
          }}
          htmlType="submit"
        >
          Submit
        </Button>
      </Form.Item>
    </FormLayout>
  );
}
