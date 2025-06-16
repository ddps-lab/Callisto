import { Col, Row, Progress, Card, Alert, Flex, Table } from 'antd';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  ResponsiveContainer
} from 'recharts';

export default function Overview() {
  const lineData = [
    { name: 'Jan', cost: 50 },
    { name: 'Feb', cost: 48 },
    { name: 'Mar', cost: 49 },
    { name: 'Apr', cost: 51 },
    { name: 'May', cost: 47 }
  ];

  const barData = [
    { name: 'Jan', cost: 90 },
    { name: 'Feb', cost: 80 },
    { name: 'Mar', cost: 85 },
    { name: 'Apr', cost: 78 },
    { name: 'May', cost: 40 }
  ];

  return (
    <>
      <Flex vertical>
        <Flex justify={'space-between'} align={'center'}>
          <h2 className="text-4xl">Overview</h2>
        </Flex>
        <Row className="mb-4">
          <Col span={24}>
            <Alert
              message="Overview page is under construction."
              type="info"
              showIcon
              className='bg-brand-200/50 text-brand-800 [&_.ant-alert-icon]:text-brand-700 border-brand-500'
            />
          </Col>
        </Row>
        <Row gutter={16} className="mb-4">
          {/* Savings Section */}
          <Col span={12}>
            <Card title="Savings" className="text-left h-full">
              <p className="font-bold text-lg">
                Cost Savings
                <span className="font-light text-sm">
                  {' '}
                  | Total usage cost: $0.00
                </span>
              </p>

              <Progress
                percent={63}
                size={['100%', 20]}
                strokeColor="#00b493"
                className="mb-8"
              />

              <ResponsiveContainer width="100%" height={180}>
                <LineChart data={lineData} className="">
                  <CartesianGrid strokeDasharray="2 2" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="cost" stroke="#00b493" />
                </LineChart>
              </ResponsiveContainer>
            </Card>
          </Col>

          {/* Cost Summary Section */}
          <Col span={12}>
            <Card title="Cost Summary" className="text-left h-full">
              <p className="font-bold text-lg m-0 pb-2">Month-to-date cost</p>
              <p className="font-bold text-4xl m-0 pb-12">$00.00</p>
              <ResponsiveContainer width="100%" height={180}>
                <BarChart data={barData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="cost" fill="#00b493" />
                </BarChart>
              </ResponsiveContainer>
            </Card>
          </Col>
        </Row>

        <Row className="mb-4">
          <Col span={24}>
            <Card title="Usage History" className="text-left h-full">
              <Table pagination={false} scroll={{ x: 'max-content' }} />
            </Card>
          </Col>
        </Row>
      </Flex>
    </>
  );
}
