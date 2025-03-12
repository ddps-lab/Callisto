/* eslint-disable react/prop-types */
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

  const MAX_CPU = 2;
  const MAX_MEMORY = 13;
  const MAX_DISK = 50;

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

    if (cpu > MAX_CPU || memory > MAX_MEMORY || disk > MAX_DISK)
      return messageApi.error(
        `The maximum value for CPU core(s) is ${MAX_CPU}, Memory is ${MAX_MEMORY}GB, and Disk is ${MAX_DISK}GB.`
      );

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

    if (cpu > MAX_CPU || memory > MAX_MEMORY || disk > MAX_DISK)
      return messageApi.error(
        `The maximum value for CPU core(s) is ${MAX_CPU}, Memory is ${MAX_MEMORY}GB, and Disk is ${MAX_DISK}GB.`
      );

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
      title={
        <h1 className="text-2xl font-bold">
          {isUpdate ? 'Modify' : 'Create'} Jupyter Notebook
        </h1>
      }
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
          {isUpdate ? 'Modify' : 'Create'}
        </Button>
      ]}
    >
      <Flex vertical style={{ marginBottom: '20px' }}>
        <h2 className="mt-5 mb-2 text-lg">Jupyter name</h2>
        <Input
          placeholder={'Name'}
          maxLength={30}
          onChange={(e) => setName(e.target.value)}
          status={name && !/^[a-zA-Z0-9-_]{1,30}$/.test(name) && 'error'}
          value={name}
        />
        {name && !/^[a-zA-Z0-9-_]{1,30}$/.test(name) && (
          <>
            <div className="text-rose-500">
              The Jupyter name can be up to 30 characters long.
            </div>

            <div className="text-rose-500">
              Only English and special characters (-, _) can be entered.
            </div>
          </>
        )}
        <h2 className="mt-5 mb-2 text-lg">CPU Core(s)</h2>
        <InputNumber
          defaultValue={1}
          placeholder="Core(s)"
          style={{
            width: '100%'
          }}
          min={1}
          max={MAX_CPU}
          parser={(value) => value.replace(/[^0-9]/g, '')}
          onChange={(value) => setCpu(value || 1)}
          value={cpu}
        />
        <h2 className="mt-5 mb-2 text-lg">Memory (GB)</h2>
        <InputNumber
          defaultValue={2}
          placeholder="Memory (GB)"
          style={{
            width: '100%'
          }}
          min={1}
          max={MAX_MEMORY}
          parser={(value) => value.replace(/[^0-9]/g, '')}
          onChange={(value) => setMemory(value || 2)}
          value={memory}
        />
        <h2 className="mt-5 mb-2 text-lg">Disk (GB)</h2>
        <InputNumber
          defaultValue={20}
          placeholder="Disk (GB)"
          style={{
            width: '100%'
          }}
          min={1}
          max={MAX_DISK}
          parser={(value) => value.replace(/[^0-9]/g, '')}
          onChange={(value) => setDisk(value || 20)}
          value={disk}
        />
      </Flex>
    </Modal>
  );
}
