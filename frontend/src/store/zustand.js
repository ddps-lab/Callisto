import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { parseJwt } from '../utils/index.js';
import { Cookies } from 'react-cookie';

const cookies = new Cookies();

export const useUserStore = create(
  persist(
    (set) => ({
      idToken: '',
      accessToken: '',
      refreshToken: '',
      userInfo: {},
      setIdToken: (idToken) => {
        set(() => ({
          idToken,
          userInfo: parseJwt(idToken)
        }));
        cookies.set('idToken', idToken);
      },
      setAccessToken: (accessToken) => {
        set(() => ({
          accessToken
        }));
        cookies.set('accessToken', accessToken);
      },
      setRefreshToken: (refreshToken) => {
        set(() => ({
          refreshToken
        }));
        cookies.set('refreshToken', refreshToken);
      },
      logout: () => {
        set(() => ({
          idToken: '',
          accessToken: '',
          refreshToken: '',
          userInfo: {}
        }));
        cookies.remove('idToken');
        cookies.remove('accessToken');
        cookies.remove('refreshToken');
      }
    }),
    {
      name: 'user-storage',
      partialize: (state) => ({
        idToken: state.idToken,
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
        userInfo: state.userInfo
      }),
      getStorage: () => localStorage
    }
  )
);

export const useChallengeStore = create((set) => ({
  session: '',
  challengeName: '',
  setChallenge: (session, challengeName) =>
    set(() => ({ session, challengeName })),
  finishChallenge: () => set(() => ({ session: '', challengeName: '' }))
}));

export const useConfirmStore = create((set) => ({
  email: '',
  setEmail: (email) => set(() => ({ email }))
}));

export const useMessageApi = create((set) => ({
  messageApi: () => {},
  setMessageApi: (messageApi) => set(() => ({ messageApi }))
}));
