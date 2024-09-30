import { ErrorMessage, InputTitle, Title } from '../styles.jsx';
import { Button, Flex, Input, InputNumber, Modal } from 'antd';
import { useEffect, useState } from 'react';
import { createJupyter, updateJupyter } from '../../apis/db/index.js';
import { useMessageApi } from '../../store/zustand.js';

export default function JupyterModal(props) {
  const { isOpen, onClose, isUpdate, idToken } = props;
  const { messageApi } = useMessageApi();

  const [name, setName] = useState('');
  const [cpu, setCpu] = useState(1);
  const [memory, setMemory] = useState(2);
  const [disk, setDisk] = useState(20);
  const [loading, setLoading] = useState(false);

  const handleResetAndClose = () => {
    setName('');
    setCpu(1);
    setMemory(2);
    setDisk(20);
    onClose();
  };

  const handleCreateJupyter = async () => {
    if (
      [name, cpu, memory, disk].some((value) => !value) ||
      !/^[a-zA-Z0-9-_]{1,30}$/.test(name)
    )
      return messageApi.error('Please enter the correct values in all fields.');
    setLoading(true);
    const jupyter = await createJupyter(idToken, {
      name,
      cpu,
      memory,
      disk
    });
    setLoading(false);

    if (!jupyter)
      messageApi.error(
        'An error occurred while creating the Jupyter instance. Please try again.'
      );
    else {
      messageApi.success('The Jupyter instance has been successfully created.');
      handleResetAndClose();
    }
  };

  const handleUpdateJupyter = async () => {
    if (
      [name, cpu, memory, disk].some((value) => !value) ||
      !/^[a-zA-Z0-9-_]{1,30}$/.test(name)
    )
      return messageApi.error('Please enter the correct values in all fields.');
    setLoading(true);
    const jupyter = await updateJupyter(idToken, {
      uid: props.jupyter.key,
      name,
      cpu,
      memory,
      disk
    });
    setLoading(false);

    if (!jupyter)
      messageApi.error(
        'An error occurred while updating the Jupyter settings. Please try again.'
      );
    else {
      messageApi.success('The Jupyter instance has been successfully updated.');
      handleResetAndClose();
    }
  };

  useEffect(() => {
    if (isUpdate) {
      setName(props?.jupyter.name);
      setCpu(props?.jupyter.cpu);
      setMemory(props?.jupyter.memory);
      setDisk(props?.jupyter.disk);
    }
  }, [isUpdate, props.jupyter]);

  return (
    <Modal
      title={<Title>{isUpdate ? 'Modify' : 'Create'} Jupyter Notebook</Title>}
      open={isOpen}
      onCancel={handleResetAndClose}
      footer={[
        <Button key="jupyter-modal-cancel" onClick={handleResetAndClose}>
          Cancel
        </Button>,
        <Button
          key="jupyter-modal-create"
          type={'primary'}
          onClick={isUpdate ? handleUpdateJupyter : handleCreateJupyter}
          loading={loading}
        >
          Create
        </Button>
      ]}
    >
      <Flex vertical style={{ marginBottom: '20px' }}>
        <InputTitle>Jupyter name</InputTitle>
        <Input
          placeholder={'Name'}
          maxLength={30}
          onChange={(e) => setName(e.target.value)}
          status={name && !/^[a-zA-Z0-9-_]{1,30}$/.test(name) && 'error'}
          value={name}
        />
        {name && !/^[a-zA-Z0-9-_]{1,30}$/.test(name) && (
          <>
            <ErrorMessage>
              The Jupyter name can be up to 30 characters long.
            </ErrorMessage>
            <ErrorMessage>
              Only English and special characters (-, _) can be entered.
            </ErrorMessage>
          </>
        )}
        <InputTitle>CPU Core(s)</InputTitle>
        <InputNumber
          defaultValue={1}
          placeholder="Core(s)"
          style={{
            width: '100%'
          }}
          min={1}
          parser={(value) => value.replace(/[^0-9]/g, '')}
          onChange={(value) => setCpu(value || 1)}
          value={cpu}
        />
        <InputTitle>Memory (GB)</InputTitle>
        <InputNumber
          defaultValue={2}
          placeholder="Memory (GB)"
          style={{
            width: '100%'
          }}
          min={1}
          parser={(value) => value.replace(/[^0-9]/g, '')}
          onChange={(value) => setMemory(value || 2)}
          value={memory}
        />
        <InputTitle>Disk (GB)</InputTitle>
        <InputNumber
          defaultValue={20}
          placeholder="Disk (GB)"
          style={{
            width: '100%'
          }}
          min={1}
          parser={(value) => value.replace(/[^0-9]/g, '')}
          onChange={(value) => setDisk(value || 20)}
          value={disk}
        />
      </Flex>
    </Modal>
  );
}
