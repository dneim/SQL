/*

Cleaning Data with SQL Queries

*/


SELECT *
FROM Sample_Data.dbo.NashvilleHouse


-------------------------------------------------------------------------------------------------------

-- Standardize Sale Date Format


SELECT SaleDate
FROM Sample_Data.dbo.NashvilleHouse


ALTER TABLE dbo.NashvilleHouse 
ALTER COLUMN SaleDate date not null


-------------------------------------------------------------------------------------------------------

-- Populate Property Address Data 


/* To find instances where an address exists, but is not populated for all lsitings 
with same ParcelID */

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHouse a
	JOIN NashvilleHouse b
		on a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

/* Use the ISNULL() func to populate ProeprtyAddress for missing listings with 
same ParcelID */

SELECT 
	a.ParcelID, 
	a.PropertyAddress, 
	b.ParcelID, 
	b.PropertyAddress,
	ISNULL (a.PropertyAddress,b.PropertyAddress) as InsertedAddresses
FROM NashvilleHouse a
	JOIN NashvilleHouse b
		on a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

/* Create update statement based on above code */

update a
set PropertyAddress = ISNULL (a.PropertyAddress,b.PropertyAddress)
FROM NashvilleHouse a
	JOIN NashvilleHouse b
		on a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-------------------------------------------------------------------------------------------------------

-- Breaking out PropertyAddress into Individual Columns (Address, City)

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM Sample_Data.dbo.NashvilleHouse


/* Create ADD statements to INSERT split data*/

ALTER TABLE dbo.NashvilleHouse
ADD PropertyAddress_Address NVARCHAR(255)

UPDATE dbo.NashvilleHouse
SET PropertyAddress_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE dbo.NashvilleHouse
ADD PropertyAddress_City NVARCHAR(255)

UPDATE dbo.NashvilleHouse
SET PropertyAddress_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

/* Verify new Columns' data*/

SELECT PropertyAddress, Property_Split_Address, Property_Split_City
FROM Sample_Data.dbo.NashvilleHouse


-------------------------------------------------------------------------------------------------------

-- Breaking out OwnerAddress into Individual Columns (Address, City, State)

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as Address,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as City,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as State
FROM Sample_Data.dbo.NashvilleHouse


/* Create ADD statements to INSERT split data*/

ALTER TABLE dbo.NashvilleHouse
ADD Owner_Split_Address NVARCHAR(255)

UPDATE dbo.NashvilleHouse
SET Owner_Split_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE dbo.NashvilleHouse
ADD Owner_Split_City NVARCHAR(255)

UPDATE dbo.NashvilleHouse
SET Owner_Split_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE dbo.NashvilleHouse
ADD Owner_Split_State NVARCHAR(255)

UPDATE dbo.NashvilleHouse
SET Owner_Split_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

/* Verify new Columns' data*/

select OwnerAddress, Owner_Split_Address, Owner_Split_City, Owner_Split_State
from NashvilleHouse

-------------------------------------------------------------------------------------------------------

-- Change 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant field

/* To review how many entires have erroneous single-letter data */

select DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
from NashvilleHouse
GROUP BY SoldAsVacant
ORDER BY 2


/* Create CASE WHEN logic for UPDATE statement*/

SELECT 
	SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'YES'
		WHEN SoldAsVacant = 'N' THEN 'NO'
		ELSE SoldAsVacant
	END
from NashvilleHouse


/* Create UPDATE statement to conver Y/N values to full Yes/No wording */

UPDATE NashvilleHouse
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'YES'
		WHEN SoldAsVacant = 'N' THEN 'NO'
		ELSE SoldAsVacant
	END

/* To verify data update */

select DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
from NashvilleHouse
GROUP BY SoldAsVacant
ORDER BY 2

-------------------------------------------------------------------------------------------------------

-- Remove Duplicates

/* Find Duplicate entries */

WITH DupsCTE AS (
SELECT *,
	ROW_NUMBER() OVER 
		(
			PARTITION BY
				ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
			ORDER BY UniqueID
		) row_num

FROM NashvilleHouse
--ORDER BY ParcelID
)

/* To remove duplicates */

DELETE
FROM DupsCTE
WHERE row_num > 1


-------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

select *
from NashvilleHouse

ALTER TABLE NashvilleHouse
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict