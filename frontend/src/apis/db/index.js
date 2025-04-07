import axios from 'axios';
import { cognitoRefreshAuth } from '../cognito';
import { useUserStore } from '../../store/zustand';

const instance = axios.create({
  baseURL: '/api',
  headers: {
    'Cache-Control': 'no-cache',
    'Content-Type': 'application/json'
  }
});

instance.interceptors.request.use(
  (config) => {
    const idToken = useUserStore.getState().idToken;
    if (idToken) {
      config.headers['id-token'] = idToken;
    }
    return config;
  },
  (error) => {
    console.error('Request error:', error);
    return Promise.reject(error);
  }
);

instance.interceptors.response.use(
  (response) => {
    return response;
  },
  async (error) => {
    const originalRequest = error.config;
    if (
      error.response &&
      error.response.status === 401 &&
      !originalRequest._retry
    ) {
      originalRequest._retry = true;
      console.error('Token expired, attempting to refresh...');
      try {
        const refreshToken = useUserStore.getState().refreshToken;
        const res = await cognitoRefreshAuth(refreshToken);
        if (res && res.idToken) {
          useUserStore.getState().setAccessToken(res.accessToken);
          useUserStore.getState().setIdToken(res.idToken);
          originalRequest.headers['id-token'] = res.idToken;
          console.log('API Token refreshed successfully.');
          return instance(originalRequest);
        } else {
          console.error('Token refresh failed or did not return tokens.');
          return Promise.reject(new Error('Token refresh failed.'));
        }
      } catch {
        console.error('Error refreshing token');
        return Promise.reject(error);
      }
    }
    return Promise.reject(error);
  }
);

export const getAllAdminJupyters = async () => {
  const response = await instance.get('/jupyter/admin').catch((e) => {
    console.log(e);
    return [];
  });
  return response?.data || [];
};

export const getJupyters = async () => {
  const response = await instance.get('/jupyter').catch((e) => {
    console.log(e);
    return [];
  });
  return response?.data || [];
};

export const createJupyter = async (jupyter) => {
  const response = await instance.post('/jupyter', jupyter).catch((e) => {
    console.log(e);
  });
  return response?.data;
};

export const updateJupyter = async (jupyter) => {
  const response = await instance
    .patch(`/jupyter/${jupyter.uid}`, jupyter)
    .catch((e) => {
      console.log(e);
    });
  return response?.data;
};

export const deleteJupyter = async (jupyterId) => {
  const response = await instance.delete(`/jupyter/${jupyterId}`).catch((e) => {
    console.log(e);
  });
  return response?.data;
};
