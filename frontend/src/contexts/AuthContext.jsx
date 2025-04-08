import { createContext, useEffect, useState } from 'react';

import { useNavigate } from 'react-router-dom';
import { useUserStore, useMessageApi } from '../store/zustand';
import { cognitoRefreshAuth } from '../apis/cognito';
import { isNAToken } from '../utils';
import PropTypes from 'prop-types';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const { refreshToken, idToken, setIdToken, setAccessToken, logout } =
    useUserStore();
  const { messageApi } = useMessageApi();
  const [isLoading, setIsLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const attemptRefresh = async () => {
      if (idToken && refreshToken) {
        if (isNAToken(idToken)) {
          console.log('AuthProvider: ID token is expired.');
          console.log('AuthProvider: Attempting token refresh...');
          const res = await cognitoRefreshAuth(refreshToken);
          if (res) {
            console.log('AuthProvider: Token refresh successful.');
            setAccessToken(res.accessToken);
            setIdToken(res.idToken);
          } else {
            console.log('AuthProvider: Token refresh failed.');
            messageApi.error('Token refresh failed. Please log in again.');
            logout();
            localStorage.clear();
            navigate('/');
          }
        }
      }
      setIsLoading(false);
    };
    attemptRefresh();
  });

  return (
    <AuthContext.Provider value={{ isLoading }}>
      {!isLoading ? children : <div>Loading...</div>}
    </AuthContext.Provider>
  );
};

AuthProvider.propTypes = {
  children: PropTypes.node.isRequired
};
