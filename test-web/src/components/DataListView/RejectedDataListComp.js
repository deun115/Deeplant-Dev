import { useState, useEffect } from 'react';
import { Box, FormControl, InputLabel, Select, MenuItem } from '@mui/material';
import DataList from './DataList';
import Spinner from 'react-bootstrap/Spinner';
import Pagination from './Children/Pagination';
import { useRejectedMeatList } from '../../API/get/getRejectedMeatListSWR';
import style from './style/rejecteddatalistcompstyle';

// 반려 데이터 목록 컴포넌트
const RejectedDataListComp = ({
  startDate, // 조회 시작 날짜
  endDate, // 조회 종료 날짜
  pageOffset, // 조회 페이지 offset
  specieValue,
}) => {
  // 고기 데이터 목록
  const [meatList, setMeatList] = useState([]);
  // 데이터 전체 개수
  const [totalData, setTotalData] = useState(0);
  // 현재 페이지 번호
  const [currentPage, setCurrentPage] = useState(1);
  // 한페이지당 보여줄 개수
  const [count, setCount] = useState(5);
  const totalPages = Math.ceil(totalData / count);

  // API fetch 데이터 전처리
  const processRejectedMeatDatas = (data) => {
    // 전체 데이터 수
    setTotalData(data['DB Total len']);
    // 반려데이터
    setMeatList(data['반려']);
  };

  //API fetch
  const { data, isLoading, isError } = useRejectedMeatList(
    currentPage - 1,
    count,
    startDate,
    endDate,
    specieValue
  );
  console.log('반려 육류 데이터 fetch 결과:', data, isLoading, isError);

  // 데이터 전처리
  useEffect(() => {
    if (data !== null && data !== undefined) {
      processRejectedMeatDatas(data);
    }
  }, [data]);

  if (data === null) return null;
  // 데이터가 로드되지 않은 경우 로딩중 반환
  if (isLoading)
    return (
      <div>
        <div style={style.listContainer}>
          <Spinner animation="border" />
        </div>
        <Box sx={style.paginationBar}>
          <div style={style.paginationContainer}>
            <Pagination
              totalDatas={totalData}
              count={count}
              currentPage={currentPage}
              setCurrentPage={setCurrentPage}
            />
            <FormControl variant="outlined" size="small" sx={style.formControl}>
              <InputLabel>Items per page</InputLabel>
              <Select
                value={count}
                onChange={(e) => setCount(e.target.value)}
                label="Items "
              >
                <MenuItem value={5}>5</MenuItem>
                <MenuItem value={10}>10</MenuItem>
                <MenuItem value={20}>20</MenuItem>
              </Select>
            </FormControl>
          </div>
        </Box>
      </div>
    );
  // 에러인 경우 경고 컴포넌트
  if (isError) return null;

  // 정상 데이터 로드 된 경우
  return (
    <div>
      <div style={style.listContainer}>
        {meatList.length > 0 ? (
          <DataList
            meatList={meatList}
            pageProp={'reject'}
            offset={currentPage - 1}
            count={count}
            startDate={startDate}
            endDate={endDate}
            pageOffset={pageOffset}
          />
        ) : (
          <Box
            sx={{
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              height: '200px',
              fontSize: '1.2rem',
              color: '#666',
            }}
          >
            검색 결과가 없습니다.
          </Box>
        )}
      </div>
      <Box sx={style.paginationBar}>
        <div style={style.paginationContainer}>
          <Pagination
            totalDatas={totalData}
            count={count}
            currentPage={currentPage}
            setCurrentPage={setCurrentPage}
          />
          <FormControl variant="outlined" size="small" sx={style.formControl}>
            <InputLabel>Items per page</InputLabel>
            <Select
              value={count}
              onChange={(e) => setCount(e.target.value)}
              label="Items per page"
            >
              <MenuItem value={5}>5</MenuItem>
              <MenuItem value={10}>10</MenuItem>
              <MenuItem value={20}>20</MenuItem>
            </Select>
          </FormControl>
        </div>
      </Box>
    </div>
  );
};

export default RejectedDataListComp;
