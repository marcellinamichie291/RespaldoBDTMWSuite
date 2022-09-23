CREATE TABLE [dbo].[Sucursal]
(
[IIDSUCURSAL] [int] NOT NULL IDENTITY(1, 1),
[NOMBRE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DIRECCION] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BHABILITADO] [int] NULL,
[FOTOSUCURSAL] [varbinary] (max) NULL,
[NOMBREFOTOSUCURSAL] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO