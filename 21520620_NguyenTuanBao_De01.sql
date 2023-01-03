--------------- Cau 1 --------------------------------------------------------
create database cuoikiCSDL
go 

use cuoikiCSDL
go


create table LOAIKHSAN(
	MALKS char(5) primary key,
	TENLKS varchar(50),
	PHANLOAI varchar(30)
)

create table KHOANGSAN(
	MAKS char(5) primary key,
	TENKS varchar(50),
	MALKS char(5),
	TRANGTHAI varchar(5),
	foreign key (MALKS) references LOAIKHSAN(MALKS)
)

create table CONGTY(
	MACTY char(5) primary key,
	TENCTY char(50),
	DIACHI char(100),
	NGAYTL smalldatetime
)

create table MOKS(
	MAMKS char(5) primary key,
	TENMO varchar(40), 
	MAKS char(5), 
	NGPHATHIEN smalldatetime,
	TINH varchar(20),
	foreign key (MAKS) references KHOANGSAN(MAKS)
)

create table KHAITHAC(
	MAMKS char(5),
	MACTY char(5),
	NGCP smalldatetime,
	NGHH smalldatetime,
	foreign key (MAMKS) references MOKS(MAMKS),
	foreign key (MACTY) references CONGTY(MACTY),
	primary key (MAMKS, MACTY, NGCP)
)

--------------- Cau 2 --------------------------------------------------------
--a
alter table KHOANGSAN
add constraint check_TrangThai
check (TRANGTHAI IN ('rắn', 'lỏng', 'khí'));

--b
--Tao trigger insert update cho khaithac, update cho congty
-- macty, ngaytl, ngcp
go
create trigger INSERT_UPDATE_KHAITHAC on KHAITHAC
for insert, update
as
begin
	declare @MACTY char(5), @NGAYTL smalldatetime, @NGCP smalldatetime
	select @MACTY = MACTY, @NGCP = NGCP
	from inserted

	select @NGAYTL = NGAYTL
	from CONGTY
	where @MACTY = MACTY

	if (@NGAYTL >= @NGCP)
	begin
		print 'LOI ! NGAY THANH LAP CONG TY PHAI NHO HON NGAY CAP PHEP'
		rollback transaction
	end
	else 
	begin
		print 'THEM / CAP NHAT DU LIEU THANH CONG'
	end
end

go
create trigger UPDATE_CONGTY on CONGTY
for update
as
begin
	declare @MACTY char(5), @NGAYTL smalldatetime, @NGCP smalldatetime
	select @MACTY = MACTY, @NGAYTL = NGAYTL
	from inserted

	declare cur_NGCP cursor
	for 
	select NGCP
	from KHAITHAC
	where @MACTY = MACTY

	open cur_NGCP
	fetch next from cur_NGCP
	into @NGCP

	while (@@FETCH_STATUS = 0)
	begin
		if (@NGAYTL >= @NGCP)
		begin
		print 'LOI ! NGAY THANH LAP CONG TY PHAI NHO HON NGAY CAP PHEP'
		rollback transaction
		end
		fetch next from cur_NGCP
		into @NGCP
	end
	close cur_NGCP
	deallocate cur_NGCP
end
go
--------------- Cau 3 --------------------------------------------------------
--a
select KHOANGSAN.MAKS, KHOANGSAN.TENKS
from KHOANGSAN
where TRANGTHAI = 'rắn'
order by MAKS DESC

--b
select KHOANGSAN.MAKS, KHOANGSAN.TENKS
from KHOANGSAN, LOAIKHSAN
where KHOANGSAN.MALKS = LOAIKHSAN.MALKS
and PHANLOAI = 'Khoáng sản năng lượng'

--c
select MOKS.MAMKS, MOKS.TENMO, CONGTY.TENCTY
from MOKS, KHAITHAC
left join CONGTY 
on CONGTY.MACTY = KHAITHAC.MACTY
where MOKS.MAMKS = KHAITHAC.MAMKS

--d
select CONGTY.MACTY
from CONGTY
where not exists(
	select *
	from MOKS
	where TINH = 'Quảng Ninh'
	and not exists(
		select * 
		from KHAITHAC
		where CONGTY.MACTY = KHAITHAC.MACTY
		and MOKS.MAMKS = KHAITHAC.MAMKS
	)
)
-- e
select KHAITHAC.MACTY , count(distinct KHAITHAC.MAMKS) as 'SOLUONGMOKS'
from KHAITHAC
where YEAR(KHAITHAC.NGCP) = 2022
group by MACTY

-- f
select CONGTY.MACTY, CONGTY.TENCTY
from CONGTY, KHAITHAC, MOKS
where CONGTY.MACTY = KHAITHAC.MACTY
and KHAITHAC.MAMKS = MOKS.MAMKS
and YEAR(NGCP) = 2022
and TINH = 'Quảng Ninh'
intersect
select CONGTY.MACTY, CONGTY.TENCTY
from CONGTY, KHAITHAC, MOKS
where CONGTY.MACTY = KHAITHAC.MACTY
and KHAITHAC.MAMKS = MOKS.MAMKS
and YEAR(NGCP) = 2022
and TINH = 'Bắc Cạn'


