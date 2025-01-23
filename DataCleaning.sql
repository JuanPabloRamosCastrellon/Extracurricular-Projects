--SELECT *
--INTO dbo.NashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--'Excel 12.0;Database=C:\Users\jpram\Downloads\Nashville Housing Data for Data Cleaning.xlsx;HDR=YES;IMEX=1;',
--'SELECT * FROM [Sheet1$]');

select * from NashvilleHousing;

select top 10 *
from nashvillehousing;

-- Standardize sale date format

select SaleDateConverted, convert(date, saledate)
from NashvilleHousing;

update NashvilleHousing
set saledate = convert(date, saledate);

alter table NashvilleHousing
add SaleDateConverted date;

update NashvilleHousing
set SaleDateConverted = convert(date, SaleDate);

-- Populate property address data

select *
from NashvilleHousing
order by ParcelID

select a.PropertyAddress, a.ParcelID, b.PropertyAddress, b.ParcelID, isnull(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
join NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null;

update a
set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
join NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null;

-- Break out address into separate columns

select PropertyAddress from NashvilleHousing;

select SUBSTRING(propertyaddress, 1, charindex(',', propertyaddress) - 1) as address,
 SUBSTRING(propertyaddress, charindex(',', propertyaddress) + 1, LEN(propertyaddress)) as address
from NashvilleHousing;

alter table NashvilleHousing
add PropertyAddressStreet nvarchar(255);

update NashvilleHousing
set PropertyAddressStreet = SUBSTRING(propertyaddress, 1, charindex(',', propertyaddress) - 1);

alter table NashvilleHousing
add PropertyAddressCity nvarchar(255);

update NashvilleHousing
set PropertyAddressCity = SUBSTRING(propertyaddress, charindex(',', propertyaddress) + 1, LEN(propertyaddress));

select PARSENAME(replace(owneraddress, ',', '.'), 3), 
PARSENAME(replace(owneraddress, ',', '.'), 2), 
PARSENAME(replace(owneraddress, ',', '.'), 1)
from NashvilleHousing

alter table NashvilleHousing
add OwnerAddressStreet nvarchar(255);

update NashvilleHousing
set OwnerAddressStreet = PARSENAME(replace(owneraddress, ',', '.'), 3)

alter table NashvilleHousing
add OwnerAddressCity nvarchar(255);

update NashvilleHousing
set OwnerAddressCity = PARSENAME(replace(owneraddress, ',', '.'), 2)

alter table NashvilleHousing
add OwnerSplitState nvarchar(255);

update NashvilleHousing
set OwnerSplitState = PARSENAME(replace(owneraddress, ',', '.'), 1)

-- Change Y and N to Yes and No in "Sold as Vacant" field

select distinct(SoldAsVacant), count(SoldAsVacant)
from NashvilleHousing
group by SoldAsVacant
order by 2

select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end
from NashvilleHousing

update NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end

-- Remove duplicates

with RowNumCTE as (
select *, ROW_NUMBER() over (
	partition by parcelid, propertyaddress, saleprice, saledate, legalreference
	order by uniqueid) row_num
from NashvilleHousing
)

delete
from RowNumCTE
where row_num > 1

-- Delete unused columns

select * from NashvilleHousing

alter table nashvillehousing
drop column owneraddress, taxdistrict, propertyaddress

alter table nashvillehousing
drop column saledate