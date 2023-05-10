/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM PortfolioProject..NashvilleHousing



/*Standardizing Date Format*/

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)



/*Populate Property Address data*/

SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress is NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL



/*Splitting Address into Individual Columns (Address, City, State)*/

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))



--Splitting the Owner Address into Invidual Columns 

SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) Address,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) City,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) State
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



/*Change Y and N to Yes and No in "Sold As Vacant* field*/

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END SoldAsVacantFixed
FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END 



/*Remove Duplicate*/

WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER (
	PARTITION BY 
		ParcelID, 
		PropertyAddress, 
		SalePrice,
		SaleDate,
		LegalReference
		ORDER BY	
			UniqueID
	) row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress



/*Delete Unused Columns*/

DROP TABLE IF EXISTS #NashvilleHousingFixed
CREATE TABLE #NashvilleHousingFixed (
	UniqueID float,
	ParcelID nvarchar(255),
	LandUse nvarchar(255),
	PropertyAddress nvarchar(255),
	SaleDate datetime,
	SalePrice float,
	LegalReference nvarchar(255),
	SoldAsVacant nvarchar(255),
	OwnerName nvarchar(255),
	OwnerAddress nvarchar(255),
	Acreage float,
	TaxDistrict nvarchar(255),
	LandValue float,
	BuildingValue float,
	TotalValue float,
	YearBuilt float,
	Bedrooms float,
	FullBath float,
	HalfBath float,
	SaleDateConverted date,
	PropertySplitAddress nvarchar(255),
	PropertySplitCity nvarchar(255),
	OwnerSplitAddress nvarchar(255),
	OwnerSplitCity nvarchar(255),
	OwnerSplitState nvarchar(255)
)

INSERT INTO #NashvilleHousingFixed
SELECT *
FROM PortfolioProject..NashvilleHousing

SELECT *
FROM #NashvilleHousingFixed

ALTER TABLE #NashvilleHousingFixed
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate