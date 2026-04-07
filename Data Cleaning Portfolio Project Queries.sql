/*

Cleaning Data in SQL Queries

*/


Select *
From PortfolioProject.dbo.housingdata;


/*  Data Analysis
- Parcel ID - ?
- Property Address - blanks -  Breaking out Address 
- Date Standardization
- SoldAsVacant - incomplete words
- OwnerName - blanks
*/


--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

select SaleDate
from PortfolioProject.dbo.HousingData;

-- i going to convert saleDate with an update

select Saledate, convert(date,saledate)
from PortfolioProject.dbo.HousingData;

update HousingData
set SaleDate = convert(Date,SaleDate);

-- It's not updating correctly; I'm going to use 
--ALTER TABLE and then an UPDATE.

alter table HousingData
add SaleDateConverted date;

update HousingData
set SaleDateConverted = convert(Date,SaleDate);

select SaleDateConverted
from PortfolioProject.dbo.HousingData;

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select PropertyAddress
From HousingData
Where PropertyAddress is null;

select *
from HousingData
--where PropertyAddress is null
order by ParcelID;

-- I sorted the data by ParcelID
-- to see which IDs are repeated and understand the relationship
-- they have with PropertyAddress. From what I observed,
-- when the IDs are the same, they contain the same information.


select 
a.ParcelID,
a.propertyaddress,
b.ParcelID,
b.PropertyAddress,
isnull(a.propertyaddress, b.propertyaddress)
from HousingData a
join HousingData b
on a.ParcelID = B.ParcelID
and a.[UniqueID ]<> b.[UniqueID ]
where a.propertyaddress is null;



-- Now I will perform an update
-- to populate a.PropertyAddress where it is NULL
-- using the values from b.PropertyAddress
-- when rows with the same ParcelID contain a valid PropertyAddress.


update a
set PropertyAddress = isnull(a.PropertyAddress,b.PropertyAddress)
from HousingData a
join HousingData b
on a.ParcelID = B.ParcelID
AND a.[UniqueID ]<> b.[UniqueID ]
where a.propertyaddress is null;


select 
ParcelID,
PropertyAddress
from HousingData
order by ParcelID;



--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


select PropertyAddress
from HousingData;

-- I will use the SUBSTRING and CHARINDEX functions
-- to split PropertyAddress into separate components
-- based on the comma delimiter.


select 
substring(propertyaddress,1,charindex(',',PropertyAddress)-1) as Address,
substring(propertyaddress,charindex(',', PropertyAddress) +1,len(propertyAddress)) as City
from HousingData;


alter table Housingdata
add PropertySplitAddress Nvarchar(255);

update HousingData
set PropertySplitAddress = substring(propertyaddress,1,charindex(',',PropertyAddress)-1); 


alter table Housingdata
add PropertySplitCity Nvarchar(255);

update HousingData
set PropertySplitCity = substring(propertyaddress,charindex(',', PropertyAddress) +1,len(propertyAddress));



Select *
From HousingData;

select
PropertysplitAddress,
propertysplitcity
from HousingData;


-- I will do the same with owneraddress but i will to use Parcename and replace
-- to OwnerAddress into separate components
-- based on the comma delimiter.


Select OwnerAddress
From HousingData;

select
parsename(replace(owneraddress, ',' , '.'), 3),
parsename(replace(owneraddress, ',' , '.'), 2),
parsename(replace(owneraddress, ',' , '.'), 1)
from HousingData;

select * from housingdata;

alter table housingdata
add OwnerSplitAddress nvarchar(255);

update HousingData
set OwnerSplitAddress = parsename(replace(owneraddress, ',' , '.'), 3);

alter table Housingdata
add OwnerSplitCity Nvarchar(255);


update HousingData
set OwnerSplitCity = parsename(replace(OwnerAddress, ',', '.') , 2);


alter table housingdata
add OwnerSplitState Nvarchar(255);

update HousingData
set OwnerSplitState = parsename(replace(OwnerAddress, ',', '.') , 1);

select  top 20
OwnerAddress,
OwnerSplitAddress,
OwnerSplitCity,
OwnerSplitState
from HousingData;



--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


select 
distinct(SoldAsVacant)
from HousingData;

-- I performed a count of distinct records to get a view of the number of incomplete entries (values)

select distinct (SoldAsVacant),
count(soldasvacant) as countValues
from HousingData
group by SoldAsVacant
order by countValues;


select 
SoldAsVacant,
case
when SoldAsVacant = 'Y' then 'YES'
when SoldAsVacant = 'N' then 'NO'
else SoldAsVacant
end
from HousingData;


update HousingData
set SoldAsVacant =
case
when SoldAsVacant = 'Y' then 'YES'
when SoldAsVacant = 'N' then 'NO'
else SoldAsVacant
end;


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

-- I want to identify duplicate rows so they can be removed.
-- To achieve this, I will use the ROW_NUMBER() window function
-- to assign a unique number to each row within a duplicate group.

select * from HousingData
--I need to partition it into things that must be unique.
--parcelid,
--propertyaddress,
--saleprice,
--saledate,
--legalreference



with rownumCTE as (
select *,
row_number() over
(partition by 
parcelid,
propertyaddress,
saleprice,
saledate,
legalreference
order by 
uniqueid) row_num
from HousingData
-- order by parcelid
)
--delete -- i will delete the duplicates 
select *
from rownumCTE
where row_num > 1
order by propertyaddress

select * from HousingData

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


select * from HousingData
-- I will remove OwnerAddress and PropertyAddress because those fields have already been split into separate columns.
-- I will also remove TaxDistrict since it is not needed for this analysis.
-- SaleDate was already transformed into a date format.


alter table Housingdata
drop column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO


















