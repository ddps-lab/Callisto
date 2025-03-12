import axios from 'axios';
import { isNAToken } from '../../utils/index.js';

const instance = (idToken) =>
  axios.create({
    baseURL: '/api',
    headers: {
      'Cache-Control': 'no-cache',
      'Content-Type': 'application/json',
      'id-token': idToken
    }
  });

export const getAllAdminJupyters = async (idToken) => {
  if (isNAToken(idToken)) {
    location.href = '/';
    return;
  }
  const response = await instance(idToken)
    .get('/jupyter/admin')
    .catch((e) => {
      console.log(e);
      return [];
    });
  return response?.data || [];
};

export const getJupyters = async (idToken) => {
  if (isNAToken(idToken)) {
    location.href = '/';
    return;
  }
  const response = await instance(idToken)
    .get('/jupyter')
    .catch((e) => {
      console.log(e);
      return [];
    });
  return response?.data || [];
};

export const createJupyter = async (idToken, jupyter) => {
  if (isNAToken(idToken)) {
    location.href = '/';
    return;
  }
  const response = await instance(idToken)
    .post('/jupyter', jupyter)
    .catch((e) => {
      console.log(e);
    });
  return response?.data;
};

export const updateJupyter = async (idToken, jupyter) => {
  if (isNAToken(idToken)) {
    location.href = '/';
    return;
  }
  const response = await instance(idToken)
    .patch(`/jupyter/${jupyter.uid}`, jupyter)
    .catch((e) => {
      console.log(e);
    });
  return response?.data;
};

export const deleteJupyter = async (idToken, jupyterId) => {
  if (isNAToken(idToken)) {
    location.href = '/';
    return;
  }
  const response = await instance(idToken)
    .delete(`/jupyter/${jupyterId}`)
    .catch((e) => {
      console.log(e);
    });
  return response?.data;
};
