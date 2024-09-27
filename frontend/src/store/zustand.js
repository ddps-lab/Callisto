import { create } from 'zustand';
import { persist } from 'zustand/middleware';

const parseJwt = (token) => {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (e) {
    console.error(e);
    return {};
  }
};

export const useUserStore = create(
  persist(
    (set) => ({
      idToken: '',
      accessToken: '',
      userInfo: {},
      setIdToken: (idToken) =>
        set(() => ({
          idToken,
          userInfo: parseJwt(idToken) // Assume parseJwt is a function to parse the token
        })),
      setAccessToken: (accessToken) =>
        set(() => ({
          accessToken
        }))
    }),
    {
      name: 'user-storage', // Key to store data in local storage
      partialize: (state) => ({
        idToken: state.idToken,
        accessToken: state.accessToken,
        userInfo: state.userInfo
      }), // 선택한 데이터만 저장
      getStorage: () => localStorage // 로컬 스토리지 사용 (디폴트)
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
