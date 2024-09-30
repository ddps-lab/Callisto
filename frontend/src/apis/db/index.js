import axios from 'axios';

const instance = (idToken) =>
  axios.create({
    baseURL: import.meta.env.VITE_DB_API_URL,
    headers: {
      'Content-Type': 'application/json',
      'id-token': idToken
    }
  });

export const getJupyters = async (idToken) => {
  const response = await instance(idToken)
    .get('/jupyter')
    .catch((e) => {
      console.log(e);
      return [];
    });
  return response?.data || [];
};

export const createJupyter = async (idToken, jupyter) => {
  const response = await instance(idToken)
    .post('/jupyter', jupyter)
    .catch((e) => {
      console.log(e);
    });
  return response?.data;
};

export const updateJupyter = async (idToken, jupyter) => {
  const response = await instance(idToken)
    .patch(`/jupyter/${jupyter.uid}`, jupyter)
    .catch((e) => {
      console.log(e);
    });
  return response?.data;
};

export const deleteJupyter = async (idToken, jupyterId) => {
  const response = await instance(idToken)
    .delete(`/jupyter/${jupyterId}`)
    .catch((e) => {
      console.log(e);
    });
  return response?.data;
};
