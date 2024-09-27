import { FormLayout } from '../styles.jsx';
import { Button, Form, Input } from 'antd';
import { cognitoConfirmSignUp } from '../../../apis/cognito/index.js';
import { useConfirmStore, useMessageApi } from '../../../store/zustand.js';
import { COGNITO_CONFIRM_STATUS } from '../../../store/constant.js';
import { useNavigate } from 'react-router-dom';

export default function Confirm() {
  const navigate = useNavigate();
  const { email } = useConfirmStore();
  const { messageApi } = useMessageApi();
  const onFinish = async ({ code }) => {
    const result = await cognitoConfirmSignUp(email, code);
    if (result.status === COGNITO_CONFIRM_STATUS.SUCCESS) {
      messageApi.info('The account has been successfully verified.');
      navigate('/');
    } else if (result.status === COGNITO_CONFIRM_STATUS.CODE_MISS_MATCH) {
      messageApi.error('The code is incorrect. Please check again.');
    } else {
      messageApi.error('An error has occurred. Please try again later.');
    }
  };
  return (
    <FormLayout onFinish={onFinish}>
      <span>
        An confirmation code has been sent to your email. Please enter the code.
      </span>
      <Form.Item
        style={{ margin: '30px 0' }}
        name="code"
        rules={[
          {
            required: true,
            message: 'Please input your code!'
          }
        ]}
      >
        <Input.OTP type="number" />
      </Form.Item>
      <Form.Item>
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
