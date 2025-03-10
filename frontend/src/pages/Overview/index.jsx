import { Flex } from 'antd';

export default function Overview() {
  return (
    <>
      <Flex vertical style={{ padding: '20px' }}>
        <Flex
          style={{ width: '100%', marginBottom: '20px' }}
          justify={'space-between'}
          vertical={true}
          align={'start'}
        >
          <h2>OverView</h2>
          <h2>Welcome To Callisto</h2>
        </Flex>
      </Flex>
    </>
  );
}
