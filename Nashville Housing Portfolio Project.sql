/*
---------------------------------- Cleaning Data in SQL --------------------------------
*/

Select *
from PortfolioProject..NashvilleHousing
;
------------------------------------------------------------------------------------------------
-- 1. Standardize Date Format
Select SaleDate
from PortfolioProject..NashvilleHousing
;

Select SaleDate, CONVERT(Date, SaleDate), FORMAT(SaleDate, 'MM/dd/yyy')
from PortfolioProject..NashvilleHousing
;

ALTER TABLE PortfolioProject..NashvilleHousing
Add SaleDateConverted Date
;

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)
;

Select SaleDateConverted
from PortfolioProject..NashvilleHousing
;

------------------------------------------------------------------------------------------------
-- 2. Populate Property Address Field

Select PropertyAddress
from PortfolioProject..NashvilleHousing
;

Select *
from PortfolioProject..NashvilleHousing
where PropertyAddress is NULL
;

Select *
from PortfolioProject..NashvilleHousing
order by ParcelID
;

-- Properties with same Parcel ID are basically the same Property hence their address should be same

Select ParcelID, PropertyAddress
from PortfolioProject..NashvilleHousing
;

-- Self Join to populate NULL fields
Select nv1.ParcelID, nv1.PropertyAddress,nv2.ParcelID, nv2.PropertyAddress, ISNULL(nv1.PropertyAddress, nv2.PropertyAddress)
from PortfolioProject..NashvilleHousing nv1
join PortfolioProject..NashvilleHousing nv2
 on nv1.ParcelID = nv2.ParcelID
where nv1.PropertyAddress is NULL and
nv2.PropertyAddress is not NULL
;

Update nv1
SET nv1.PropertyAddress = nv2.PropertyAddress
from PortfolioProject..NashvilleHousing nv1
join PortfolioProject..NashvilleHousing nv2
 on nv1.ParcelID = nv2.ParcelID
where nv1.PropertyAddress is NULL and
nv2.PropertyAddress is not NULL
;

------------------------------------------------------------------------------------------------
-- 3. Split PropertyAddress and OwnerAddress into individual columns (Address, City, State)

Select PropertyAddress
from PortfolioProject..NashvilleHousing
;

-- Using comma ',' as a delimiter here to separate the city from the address
Select PropertyAddress,
SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress)) as Addresswithcomma, 
SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress)-1) as Address,
CHARINDEX(',', PropertyAddress),
SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+2,LEN(PropertyAddress)) as City
from PortfolioProject..NashvilleHousing
;

ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitAddress Nvarchar(255),
	PropertySplitCity Nvarchar(255)
;

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress)-1),
	PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+2,LEN(PropertyAddress))
;

Select PropertyAddress, PropertySplitAddress, PropertySplitCity
from PortfolioProject..NashvilleHousing
;


-- Split Owner Address into Address, City and State using PARSENAME
Select OwnerAddress
from PortfolioProject..NashvilleHousing
;


Select OwnerAddress,
PARSENAME(OwnerAddress,1)
from PortfolioProject..NashvilleHousing
;

Select OwnerAddress,
PARSENAME(REPLACE(OwnerAddress,',', '.'),1) as OwnerSplitState,
PARSENAME(REPLACE(OwnerAddress,',', '.'),2) as OwnerSplitCity,
PARSENAME(REPLACE(OwnerAddress,',', '.'),3) as OwnerSplitAddress
from PortfolioProject..NashvilleHousing
;

ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitAddress Nvarchar(255),
	OwnerSplitCity Nvarchar(255),
	OwnerSplitState Nvarchar(255)
;

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'),3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'),2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'),1)
;

Select OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
from PortfolioProject..NashvilleHousing
;


------------------------------------------------------------------------------------------------
-- 4. Change Y and N to Yes and No in "Sold as Vacant" field

select distinct(SoldasVacant), count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2
;

Select SoldAsVacant,
case
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	ELSE SoldAsVacant
end as SoldAsVacantUpdated
from PortfolioProject..NashvilleHousing
-- where SoldAsVacant='Y'
;

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = case
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	ELSE SoldAsVacant
end
;

-- to check the above update worked, now we should just have Yes and no and their counts
select distinct(SoldasVacant), count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2
;

------------------------------------------------------------------------------------------------
-- 5. Remove Duplicates
-- Using CTE

-- Seeing the duplicates first
with cte as
(
select *,
ROW_NUMBER() OVER(PARTITION BY ParcelId, 
							   PropertyAddress, 
							   SalePrice, 
							   SaleDate, 
							   LegalReference 
				  ORDER BY UniqueID) as row_num
from PortfolioProject..NashvilleHousing
)

select *
from cte
where row_num >1
order by PropertyAddress
;

-- deleting the duplicates now
with cte as
(
select *,
ROW_NUMBER() OVER(PARTITION BY ParcelId, 
							   PropertyAddress, 
							   SalePrice, 
							   SaleDate, 
							   LegalReference 
				  ORDER BY UniqueID) as row_num
from PortfolioProject..NashvilleHousing
)

delete 
from cte
where row_num >1
;

------------------------------------------------------------------------------------------------
-- 6. Delete Unused Columns

ALTER TABLE PortfolioProject..NashvilleHousing
Drop Column SaleDate, PropertyAddress, OwnerAddress, TaxDistrict;
