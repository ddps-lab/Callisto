/* eslint-disable react/prop-types */
import { Form } from 'antd';

export const FormLayout = ({ children, onFinish }) => (
  <div className="flex flex-col w-full h-full justify-center items-center bg-gray-200">
    <div className="bg-white p-4 md:p-5 rounded-lg shadow-md w-80">
      <h1 className="font-thin tracking-tight">Callisto</h1>
      <Form
        className="w-full"
        layout="vertical"
        autoComplete="off"
        onFinish={onFinish}
      >
        {children}
      </Form>
    </div>
  </div>
);
