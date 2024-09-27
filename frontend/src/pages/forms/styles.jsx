import styled from 'styled-components';
import { Form } from 'antd';

const PageContainer = styled.div`
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  justify-content: center;
  align-items: center;
  background: #eee;
`;

const FormWrapper = styled.div`
  background: #fff;
  padding: 10px 20px;
  border-radius: 8px;
  box-shadow: 0 0 10px #ccc;

  > .title {
    font-weight: 100;
    letter-spacing: -1px;
  }
`;

export const FormLayout = ({ children, onFinish }) => (
  <PageContainer>
    <FormWrapper>
      <h1 className="title">Callisto</h1>
      <Form
        style={{ width: '350px' }}
        layout="vertical"
        autoComplete="off"
        onFinish={onFinish}
      >
        {children}
      </Form>
    </FormWrapper>
  </PageContainer>
);
