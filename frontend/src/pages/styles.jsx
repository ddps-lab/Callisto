import styled from 'styled-components';

export const Title = styled.div`
  font-size: 18px;
  font-weight: 600;
`;

export const InputTitle = styled(Title)`
  margin-top: 20px;
  margin-bottom: ${(props) => (props?.size === 'xs' ? '4px' : '8px')};
  ${(props) => props?.size === 'xs' && 'font-size: 16px;'}
`;

export const ErrorMessage = styled.div`
  color: #ff4d4f;
`;
