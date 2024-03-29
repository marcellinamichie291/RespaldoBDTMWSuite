SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- Procedimiento para leer los movimientos que inserta QSP
-- y pasarlos a la tabla checkcall.
--DROP PROCEDURE sp_lee_movs_QSP
--GO

--exec sp_lee_movs_QSP

CREATE  PROCEDURE [dbo].[sp_lee_movs_QSP]
AS

DECLARE	
	@V_idTransaccion 	uniqueidentifier, 
	@V_fecha		Datetime, 
	@V_proximidadCiudad	Varchar(500), 
	@V_latitud		Float, 
	@V_longitud		Float, 
	@V_economico		Varchar(50), 
	@V_ignicion		Varchar(10), 
	@V_proximidadPoblacion	Varchar(500),
	@V_IDOPERA		Varchar(10),
	@V_ENC_APAG		Char(1),
	@V_CONSECCKC		BigInt,
	@V_TIPOCUENTA		int,
	@V_ANTENA		Varchar(50),
	@V_DESCRIPCTA		Varchar(10),
	@V_GPSLOCATION		Varchar(255),
	@V_velocidad		Float,
	@V_registros		integer,
	@V_i				integer,
	@V_NombreSitio		Varchar(500),
	@V_lastckc          Varchar(500),
	@V_estatuspo          Varchar(4),
	@V_Comentario		Varchar(500),
	@V_dato_vel			Varchar(4)

DECLARE @TTMovs_QSP TABLE(
		QSP_idtransaccion	uniqueidentifier not null,
		QSP_date		DateTime null,
		QSP_comment		Varchar(500) NULL,
		QSP_latseconds		Float null,
		QSP_longseconds		Float null,
		QSP_tractor		Varchar(50) NULL,
		QSP_vehicleignition	bit NULL,
		QSP_commentlarge	Varchar(500) NULL,
		QSP_cuenta		Int Null,
		QSP_velMax		float null,
		QSP_nombreSitio VARCHAR(500))

SET NOCOUNT ON

BEGIN --1 Principal

if   (select max(activitydatetime) from qsp.dbo.qfsactivity  with (nolock)) <=  (select DATEADD([minute],-20,getdate() )) 



BEGIN

--update qsp.dbo.qfsactivity set activitydatetime = (DATEADD([minute],-10,getdate() ))
--where activitydatetime = (select max(activitydatetime) from qsp.dbo.qfsactivity)
if ((select enviado from  QSP.dbo.QFS_mailflag) = 'No')
BEGIN
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'smtp TDR',
    @recipients = 'emolvera@tdr.com.mx;jmartinez@tdr.com.mx;supervisorcems@tdr.com.mx;jrlopez@tdr.com.mx',
    @body = 'SE perdio la conexion con el servidor QFS, se esta intentando re-conectar' ,
    @subject = 'Sin posiciones en Checkcalls',
    @attach_query_result_as_file = 0 ;

update QSP.dbo.QFSControl set Fecha = dateadd(n,10,Fecha)  where idTabla = 1
--select dateadd(n,10,Fecha) from QSP.dbo.QFSControl  where idTabla = 1

update QSP.dbo.QFS_mailflag set enviado = 'Si'

END

END

ELSE 

update QSP.dbo.QFS_mailflag set enviado = 'No'





-- Inserta en la tabla temporal la información que haya en la de paso TPosicion
INSERT Into @TTMovs_QSP 
	/*SELECT 	QF.idActivity, 
		QF.receivedDateTime, 
		QF.location, 
		QF.latitude, 
		QF.longitud, 
		v.displayName, 
		QF.ignitionOn, 
		QF.location ,
		1,
		QF.maxSpeed,
		QFS.displayName
	FROM  QSP..QFSVehicles v with (nolock), QSP..QFSActivity  QF  with (nolock), QSP..QFSSites QFS with (nolock)
	where v.vehicleId=QF.vehicleId and
		  QF.SiteId = QFS.SiteId  and leido = 'no' --and eventsubtype in ('SMDP_EVENT_TIME_OR_DISTANCE')
		and QF.receivedDateTime > DateAdd(dd, -1,getdate())*/

SELECT 	QF.idActivity, 
		QF.receivedDateTime, 
		QF.location, 
		abs(QF.latitude*3600), 
		abs(QF.longitud*3600), 
		v.displayName, 
		QF.ignitionOn, 
		QF.location ,
		1,
		QF.Speed,
		QFS.displayName
FROM QSP..QFSVehicles v with (nolock), QSP..QFSActivity  QF  with (nolock) left join QSP..QFSSites QFS with (nolock) on (QF.SiteId = QFS.SiteId  )
	where v.vehicleId=QF.vehicleId and
		  leido = 'no' and 
		-- eventsubtype in ('SMDP_EVENT_TIME_OR_DISTANCE') and
		  QF.receivedDateTime > DateAdd(dd, -1,getdate()) 
		 --and v.displayName = '1229'

--se agrego que eñ tipo de evento solo fuera pos SMDP_EVENT_TIME_OR_DISTANCE
-- ya que la consulta trai todo tipo de movimientos provocando registros uy repetidos.

--Se obtiene el total de registros de la tabla temporal
select @V_registros =  (Select count(*) From  @TTMovs_QSP)
--print @V_registros
--Se inicializa el contador en 1
select @V_i = 1

-- Si hay movimientos en la tabla continua
	If Exists ( Select count(*) From  @TTMovs_QSP )
	BEGIN --3 Si hay movimientos de posiciones

		
		-- Se declara un curso para ir leyendo la tabla de paso
		DECLARE Posiciones_Cursor CURSOR FOR 
		SELECT QSP_idtransaccion, QSP_date, QSP_comment, QSP_latseconds, QSP_longseconds, QSP_tractor, QSP_vehicleignition, QSP_commentlarge, QSP_cuenta, QSP_velMax, QSP_nombreSitio	
		FROM @TTMovs_QSP 
	
		OPEN Posiciones_Cursor 
		FETCH NEXT FROM Posiciones_Cursor INTO @V_idTransaccion, @V_fecha, @V_proximidadCiudad, @V_latitud, @V_longitud, @V_economico, @V_ignicion, @V_proximidadPoblacion, @V_TIPOCUENTA, @V_velocidad, @V_NombreSitio	
		--Mientras la lectura sea correcta y el contador sea menos al total de registros
		WHILE (@@FETCH_STATUS = 0 and @V_i < @V_registros)
		BEGIN -- del cursor Unidades_Cursor --3
		SELECT @V_idTransaccion, @V_fecha, @V_proximidadCiudad, @V_latitud, @V_longitud, @V_economico, @V_ignicion, @V_proximidadPoblacion, @V_TIPOCUENTA, @V_velocidad, @V_NombreSitio	

		--Valida que el numero economico no sea el numero de antena.
		--IF @V_economico <> Null
			--BEGIN	--cuando valida si la antena es dif al numero economico
				-- Busca el ID del operador segun su unidad
				SELECT @V_IDOPERA = IsNull(trc_driver,'XXX')
				FROM tmwSuite..tractorprofile 
				WHERE trc_number = @V_economico;
		
				-- Define si esta Apgado o Encendido el motor
				IF @V_ignicion = 1 
				Begin
					Select @V_ENC_APAG = 'Y'
				End
				IF @V_ignicion = 0
				Begin
					Select @V_ENC_APAG = 'N'
				End
		
				-- Multiplica por 3600 latitud y longitud
				Select @V_latitud	=	@V_latitud 
				Select @V_longitud	=	@V_longitud 

				-- Define el tipo de sistema localizador tiene
				-- sistema 1 QSP, 2 OTS/ATF
				IF @V_TIPOCUENTA = 1
				Begin
					Select @V_DESCRIPCTA = ' '
				End
				IF @V_TIPOCUENTA = 2
				Begin
--					Select @V_DESCRIPCTA = ' Sis-OTS/ATF'
					Select @V_DESCRIPCTA = ' * '
				End

				-- Valida que el valor del SiteId (Nombre) no sea Null
				Select @V_NombreSitio = IsNull(@V_NombreSitio,' ')
				Select @V_lastckc =  (select  rtrim(replace(replace(trc_lastpos_nearctynme,'[',''),']','')) from tmwsuite.dbo.tractorprofile where trc_number =  @V_economico) 

				-- Reemplaza el dato del UNKNOWN por un '-'
				SELECT @V_proximidadCiudad	=	REPLACE(@V_proximidadCiudad,'UNKNOWN','-')
				SELECT @V_proximidadPoblacion	=	REPLACE(@V_proximidadPoblacion,'UNKNOWN','-')

				
				SELECT @V_GPSLOCATION 		= left((@V_proximidadCiudad + @V_DESCRIPCTA),255)
				select @V_dato_vel = convert(varchar(4),@V_velocidad)
				-- Concatena el valor del SiteId (Nombre)
				
				
-----------------------------------------CASO EN EL CUAL LA POSICION ES UN SITIO------------------------------------------------------------------------------------------------------	
				
				IF @V_NombreSitio != ' '
					Begin
					    Select @V_estatuspo = 'SIT'
						Select @V_NombreSitio = '['+@V_NombreSitio+'] '
						
						SELECT @V_GPSLOCATION 	= left(@V_NombreSitio + 'Vel. '+@V_dato_vel,255)
						
						
						if @V_lastckc = ''
													  BEGIN
                                                       SELECT @V_Comentario = 'Entrando a: '  + left(('[' + @V_ENC_APAG + '] '  + @V_NombreSitio+ ' Vel. '+cast( @V_dato_vel as varchar(4))), 254)
													  END
													 ELSE
													  BEGIN
													    SELECT @V_Comentario = left(('[' + @V_ENC_APAG + '] '  + @V_NombreSitio+ ' Vel. '+cast( @V_dato_vel as varchar(4))), 254)
													  END
						
					End
				Else



-----------------------------------------CASO EN EL CUAL LA POSICION NO ES UN SITIO------------------------------------------------------------------------------------------------------
				
				
				
					Begin
					     

						 	if @V_lastckc <> ''
													 BEGIN
													 Select @V_estatuspo = 'SIT'
													   Select @V_Comentario = 'Saliendo de: ' +  left(('[' + @V_lastckc + '] '+  ' Vel. '+cast(@V_dato_vel as varchar(4))),254)
													 END
													ELSE
													  BEGIN
													  Select @V_estatuspo = 'TRP'
													   Select @V_Comentario =  left(('[' + @V_ENC_APAG + '] '+ left(@V_proximidadCiudad,254) + ' Vel. '+cast(@V_dato_vel as varchar(4))),254)
													 END
						
					End
				
		
				-- Lee el consecutivo de los checkcall para hacer el insert a la tabla.					
				execute @V_CONSECCKC = tmwSuite..getsystemnumber_gateway N'CKCNUM' , NULL , 1 
				-- Inserta el nuevo checkcall
				Insert tmwSuite.. checkcall(
				ckc_number, ckc_status, ckc_asgntype, ckc_asgnid, ckc_date, ckc_event, ckc_city, ckc_comment, 
				ckc_updatedby, ckc_updatedon, ckc_latseconds, ckc_longseconds, ckc_lghnumber, ckc_tractor, ckc_extsensoralarm, ckc_vehicleignition, 
				ckc_milesfrom, ckc_directionfrom, ckc_validity, ckc_mtavailable, ckc_minutes, ckc_mileage, ckc_home, ckc_cityname, 
				ckc_state, ckc_zip, ckc_commentlarge, ckc_minutes_to_final, ckc_miles_to_final, ckc_Odometer, TripStatus, ckc_odometer2, 
				ckc_speed, ckc_speed2, ckc_heading, ckc_gps_type, ckc_gps_miles, ckc_fuel_meter, ckc_idle_meter)
				Values (@V_CONSECCKC, 'HIST', 		'DRV', 	@V_IDOPERA,	@V_fecha, 	@V_estatuspo, 		0, 	@V_Comentario, 
					'QFS', 		GetDate(), 	@V_latitud,	@V_longitud, 		0, 		@V_economico, 	Null, 	@V_ENC_APAG, 
					1,		Null, 		Null, 	Null, 		0, 		0, 		Null, 	Null, 
					Null, 		Null, 		left((@V_proximidadPoblacion + @V_DESCRIPCTA),254), 		0,		0,		0,		0,	0,		
					@V_dato_vel, 		Null, 		Null, 	Null, 		Null, 		Null, 		Null)			
				-- Se actualiza tambien en el catalogo de las unidades la ultima ubicacion
				-- siempre y cuando la fecha sea mayor de la que tiene.

		IF (@V_GPSLOCATION != NULL)
		 BEGIN
				update tmwSuite..tractorprofile 
				set trc_gps_desc = '.[' + @V_ENC_APAG + ']' +@V_GPSLOCATION, 
				    trc_gps_date = @V_fecha ,
					trc_lastpos_nearctynme = @V_NombreSitio,
					trc_gps_speed = @V_dato_vel
				where 	trc_gps_date <= @V_fecha and trc_number = @V_economico
				print 'localizacion ' + cast(@V_GPSLOCATION as nvarchar(30))
				print 'Fecha ' + cast(@V_fecha as nvarchar(30))
				print 'Num Camion ' + cast(@V_economico as nvarchar(30))
		 END
		Else 
		 BEGIN
				update tmwSuite..tractorprofile 
				set trc_gps_desc =  '.[' + @V_ENC_APAG + ']'+@V_GPSLOCATION, 
				    trc_gps_date = @V_fecha,  
					trc_lastpos_nearctynme = @V_NombreSitio, 
					trc_gps_speed = @V_dato_vel
				where 	trc_gps_date <= @V_fecha and trc_number = @V_economico
				print 'localizacion ' + cast(@V_GPSLOCATION as nvarchar(30))
				print 'Fecha ' + cast(@V_fecha as nvarchar(30))
				print 'Num Camion ' + cast(@V_economico as nvarchar(30))
		 END

			
			
			--END --cuando valida si la antena es dif al numero economico
				-- Elimina los renglones de la tabla de paso
				--delete QSP..QFSActivity 
				--where  QSP..QFSActivity.idActivity = @V_idTransaccion;
				-- marca cada uno de los registros para que se eliminen despues.
				Update QSP..QFSActivity  Set leido = 'si' 
				--where  QSP..QFSActivity.idActivity = @V_idTransaccion;
				
				--Se aumenta el contador en 1.
				select @V_i = @V_i + 1

		FETCH NEXT FROM Posiciones_Cursor INTO @V_idTransaccion, @V_fecha, @V_proximidadCiudad, @V_latitud, @V_longitud, @V_economico, @V_ignicion, @V_proximidadPoblacion, @V_TIPOCUENTA, @V_velocidad, @V_NombreSitio
		                             
	
	END --3 curso de los movimientos 

	CLOSE Posiciones_Cursor 
	DEALLOCATE Posiciones_Cursor 

END -- 2 si hay movimientos del RC

END --1 Principal


GO
