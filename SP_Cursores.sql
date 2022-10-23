USE TallerMecanico
GO
---Cursor1---
Create procedure SP_CalculoDeMaximoRepuesto
@Marca as nvarchar,
@CantidadDeRepuestoMasUsado int output,
@RepuestoIdMasUsado int output
AS
BEGIN
SET NOCOUNT ON

	CREATE TABLE [dbo].[TablaDeComparación]([Cantidad] [int] NULL,[Nombre] [nvarchar](50) NULL,[RepuestoId] [int] NULL)

	DECLARE @VehiculoId AS int
	DECLARE Cursor_Cantidad_Repuestos CURSOR
	FOR SELECT VehiculoId FROM Vehiculo where Marca = @Marca
	OPEN Cursor_Cantidad_Repuestos
	FETCH NEXT FROM Cursor_Cantidad_Repuestos INTO @VehiculoId 
	WHILE @@fetch_status = 0
	BEGIN
		Select D.Cantidad, R.Nombre, R.RepuestoId into #TempTable From [dbo].[Desperfecto] as D 
		Inner join [dbo].[Repuesto_Desperfecto] as RD on RD.DesperfectoID = D.DesperfectoId
		inner join [dbo].[Repuesto] as R on RD.RepuestoID = R.RepuestoId  where VehiculoId = @VehiculoId
		---
		Declare
		@Cantidad as int, 
		@Nombre as nvarchar(50), 
		@RepuestoId as int
			---
		DECLARE Cursor_TablaTemporal CURSOR
		FOR SELECT Cantidad,Nombre,RepuestoId FROM #TempTable
		OPEN Cursor_TablaTemporal
		FETCH NEXT FROM Cursor_TablaTemporal INTO @Cantidad, @Nombre, @RepuestoId 
		WHILE @@fetch_status = 0
		BEGIN
			insert into [dbo].[TablaDeComparación]([Cantidad],[Nombre],[RepuestoId]) 
			values (@Cantidad, @Nombre, @RepuestoId)
		FETCH NEXT FROM Cursor_TablaTemporal INTO @Cantidad, @Nombre, @RepuestoId 
		END
		CLOSE Cursor_TablaTemporal
		DEALLOCATE Cursor_TablaTemporal
		---
		drop table #TempTable
		FETCH NEXT FROM Cursor_Cantidad_Repuestos INTO @VehiculoId
	END
	CLOSE Cursor_Cantidad_Repuestos
	DEALLOCATE Cursor_Cantidad_Repuestos

	CREATE TABLE [dbo].[Tabla](CANTIDAD_TOTAL [int] NULL,[RepuestoId] [int] NULL)

	DECLARE Cursor_Cantidad_Maxima_Repuestos CURSOR
	FOR SELECT DISTINCT([RepuestoId]) from [dbo].[TablaDeComparación]  
	OPEN Cursor_Cantidad_Maxima_Repuestos
	FETCH NEXT FROM Cursor_Cantidad_Maxima_Repuestos INTO @RepuestoId
	WHILE @@fetch_status = 0
	BEGIN
		INSERT INTO [dbo].[Tabla] (CANTIDAD_TOTAL, REPUESTOID)
		VALUES ((SELECT SUM(CANTIDAD) FROM [dbo].[TablaDeComparación] WHERE [RepuestoId] = @RepuestoId), @RepuestoId )
		
		FETCH NEXT FROM Cursor_Cantidad_Maxima_Repuestos INTO @RepuestoId
	END
	CLOSE Cursor_Cantidad_Maxima_Repuestos
	DEALLOCATE Cursor_Cantidad_Maxima_Repuestos

	SELECT TOP(1) @CantidadDeRepuestoMasUsado=CANTIDAD_TOTAL, @RepuestoIdMasUsado=[RepuestoId] FROM [dbo].[Tabla] ORDER BY CANTIDAD_TOTAL DESC

	DROP TABLE [dbo].[Tabla]
	DROP TABLE [dbo].[TablaDeComparación]
END