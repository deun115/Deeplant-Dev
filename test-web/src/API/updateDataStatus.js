import { apiIP } from '../config';

// 데이터 상태 변경 함수 updateDataStatus를 export
export const updateDataStatus = async (confirmVal, meatId, setStateChanged) => {
  try {
    const response = await fetch(
      //query parameter : confirmVal, id
      `http://${apiIP}/meat/update/${confirmVal}?meatId=${meatId}`,
      {
        method: 'PATCH',
      }
    );
    setStateChanged(true);

    //response status가 200 (OK)이 아닌 경우,  에러 throw
    if (!response.ok) {
      throw new Error('서버에서 응답 코드가 성공(2xx)이 아닙니다.');
    }
    //response status가 200 (OK)인 경우, JSON을 파싱한 후 data 반환
    const responseData = await response.json();
    return responseData;
  } catch (err) {
    console.error(err);
  }
};
export default updateDataStatus;
