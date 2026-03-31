-- Kastamonu_Su_Sebekesi_DB.sql
USE master;
GO

IF DB_ID('KastamonuSuSebekeDB') IS NOT NULL
BEGIN
    ALTER DATABASE KastamonuSuSebekeDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE KastamonuSuSebekeDB;
END
GO

CREATE DATABASE KastamonuSuSebekeDB;
GO

USE KastamonuSuSebekeDB;
GO

-- 1. Bolge (Region) Table
CREATE TABLE Bolgeler (
    BolgeID INT IDENTITY(1,1) PRIMARY KEY,
    BolgeAdi NVARCHAR(100) NOT NULL
);

-- 2. ArizaSenaryolari (Fault Scenarios) Table
CREATE TABLE Senaryolar (
    SenaryoID INT IDENTITY(1,1) PRIMARY KEY,
    SenaryoAdi NVARCHAR(100) NOT NULL,
    Aciklama NVARCHAR(255)
);

-- 3. Musteriler (Customers) Table
CREATE TABLE Musteriler (
    MusteriID INT IDENTITY(1,1) PRIMARY KEY,
    Ad NVARCHAR(50),
    Soyad NVARCHAR(50),
    Telefon NVARCHAR(20),
    Adres NVARCHAR(255),
    BolgeID INT FOREIGN KEY REFERENCES Bolgeler(BolgeID)
);

-- 4. Ekipler (Maintenance Teams) Table
CREATE TABLE Ekipler (
    EkipID INT IDENTITY(1,1) PRIMARY KEY,
    EkipAdi NVARCHAR(100) NOT NULL,
    SorumluBolgeID INT FOREIGN KEY REFERENCES Bolgeler(BolgeID)
);

-- 5. ArizaKacakKayitlari (Fault and Leak Records) Table
CREATE TABLE ArizaKacakKayitlari (
    KayitID INT IDENTITY(1,1) PRIMARY KEY,
    BolgeID INT FOREIGN KEY REFERENCES Bolgeler(BolgeID),
    SenaryoID INT FOREIGN KEY REFERENCES Senaryolar(SenaryoID),
    MusteriID INT NULL FOREIGN KEY REFERENCES Musteriler(MusteriID),
    EkipID INT NULL FOREIGN KEY REFERENCES Ekipler(EkipID),
    BildirimTarihi DATETIME DEFAULT GETDATE(),
    MudahaleTarihi DATETIME NULL,
    CozumTarihi DATETIME NULL,
    Durum NVARCHAR(50) DEFAULT 'Bekliyor', -- Bekliyor, İnceleniyor, Çözüldü
    AciliyetDerecesi NVARCHAR(20), -- Düşük, Orta, Yüksek, Kritik
    KoordinatX FLOAT,
    KoordinatY FLOAT,
    Aciklama NVARCHAR(MAX)
);
GO

-- Insert 8 Scenarios
INSERT INTO Senaryolar (SenaryoAdi, Aciklama) VALUES
('Boru Patlağı', 'Ana veya ara şebeke borularında fiziksel patlak'),
('Basınç Düşüklüğü', 'Bölgesel olarak su basıncının standartların altına inmesi'),
('Kaçak Su Kullanımı', 'Sayaca müdahale veya şebekeden izinsiz hat çekilmesi'),
('Vana Arızası', 'Şebeke yönlendirme veya kesme vanalarının çalışmaması'),
('Sayaç Arızası', 'Abone su sayacının okumaması veya hatalı okuması'),
('Su Kalitesi İhlali', 'Suda bulanıklık, koku veya renk değişimi ihbarı'),
('Planlı Bakım Kesintisi', 'Bölgedeki planlı altyapı çalışmaları nedeniyle kesinti'),
('Pompa İstasyonu Arızası', 'Suyu şebekeye basan pompa istasyonlarında elektriksel/mekanik arıza');

-- Insert Regions (Kastamonu Districts/Neighborhoods) - 20 Regions
INSERT INTO Bolgeler (BolgeAdi) VALUES
('Merkez'), ('Abana'), ('Ağlı'), ('Araç'), ('Azdavay'), ('Bozkurt'), ('Cide'), ('Çatalzeytin'),
('Daday'), ('Devrekani'), ('Doğanyurt'), ('Hanönü'), ('İhsangazi'), ('İnebolu'), ('Küre'), 
('Pınarbaşı'), ('Seydiler'), ('Şenpazar'), ('Taşköprü'), ('Tosya');

-- Insert Teams
INSERT INTO Ekipler (EkipAdi, SorumluBolgeID) VALUES
('Merkez Acil Müdahale', 1), ('Kuzey İlçe Ekibi', 2), ('Batı İlçe Ekibi', 4), ('Doğu İlçe Ekibi', 19), ('Güney İlçe Ekibi', 20);

GO

-- Generate mock customers (1000 records)
SET NOCOUNT ON;
BEGIN TRANSACTION;
DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO Musteriler (Ad, Soyad, Telefon, Adres, BolgeID)
    VALUES (
        'Ad' + CAST(@i AS NVARCHAR(10)), 
        'Soyad' + CAST(@i AS NVARCHAR(10)), 
        '0555' + RIGHT('000000' + CAST(CAST(RAND() * 1000000 AS INT) AS NVARCHAR(6)), 6),
        'Kastamonu Adres ' + CAST(@i AS NVARCHAR(10)),
        CAST(RAND() * 20 + 1 AS INT) -- 1 to 20
    );
    SET @i = @i + 1;
END;
COMMIT TRANSACTION;
GO

-- Generate 5050+ Fault/Leak records (Minimum 5000 required)
SET NOCOUNT ON;
BEGIN TRANSACTION;
DECLARE @j INT = 1;

WHILE @j <= 5500
BEGIN
    DECLARE @Durum NVARCHAR(50);
    DECLARE @Aciliyet NVARCHAR(20);
    DECLARE @RandomVal FLOAT;
    DECLARE @EkipID INT = NULL;
    DECLARE @BildirimTarihi DATETIME;
    DECLARE @MudahaleTarihi DATETIME = NULL;
    DECLARE @CozumTarihi DATETIME = NULL;

    -- Tarih ataması (Son 2 yıl içinde rastgele)
    SET @BildirimTarihi = DATEADD(day, -CAST(RAND() * 730 AS INT), GETDATE());
    SET @BildirimTarihi = DATEADD(minute, -CAST(RAND() * 1440 AS INT), @BildirimTarihi);

    -- Durum ataması
    SET @RandomVal = RAND();
    IF @RandomVal < 0.15 SET @Durum = 'Bekliyor';
    ELSE IF @RandomVal < 0.35 SET @Durum = 'İnceleniyor';
    ELSE SET @Durum = 'Çözüldü';

    -- Aciliyet ataması
    SET @RandomVal = RAND();
    IF @RandomVal < 0.20 SET @Aciliyet = 'Düşük';
    ELSE IF @RandomVal < 0.50 SET @Aciliyet = 'Orta';
    ELSE IF @RandomVal < 0.85 SET @Aciliyet = 'Yüksek';
    ELSE SET @Aciliyet = 'Kritik';

    -- Ekip Ataması
    IF @Durum IN ('İnceleniyor', 'Çözüldü')
    BEGIN
        -- 1 to 5
        SET @EkipID = CAST(RAND() * 5 + 1 AS INT);
        -- Mudahale tarihi
        SET @MudahaleTarihi = DATEADD(minute, CAST(RAND() * 300 + 30 AS INT), @BildirimTarihi);
    END

    -- Çözüm Tarihi Ataması
    IF @Durum = 'Çözüldü'
    BEGIN
        SET @CozumTarihi = DATEADD(minute, CAST(RAND() * 1440 + 60 AS INT), @MudahaleTarihi);
    END

    INSERT INTO ArizaKacakKayitlari (BolgeID, SenaryoID, MusteriID, EkipID, BildirimTarihi, MudahaleTarihi, CozumTarihi, Durum, AciliyetDerecesi, KoordinatX, KoordinatY, Aciklama)
    VALUES (
        CAST(RAND() * 20 + 1 AS INT), -- 1 to 20 bolge
        CAST(RAND() * 8 + 1 AS INT), -- 1 to 8 senaryo
        CASE WHEN RAND() < 0.8 THEN CAST(RAND() * 1000 + 1 AS INT) ELSE NULL END, -- 80% ihtimalle musteri bildirimi
        @EkipID,
        @BildirimTarihi,
        @MudahaleTarihi,
        @CozumTarihi,
        @Durum,
        @Aciliyet,
        41.3781 + (RAND() * 0.1 - 0.05), -- Kastamonu approx coords
        33.7753 + (RAND() * 0.1 - 0.05),
        'Otomatik oluşturulmuş sistem kaydı.'
    );

    SET @j = @j + 1;
END;
COMMIT TRANSACTION;
GO

PRINT 'Kastamonu Su Sebekesi veritabani kurulumu ve 5500 sahte veri aktarimi basariyla tamamlandi.';
GO
