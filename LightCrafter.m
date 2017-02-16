%AUTHOR: Jan Winter, TU Berlin, FG Lichttechnik j.winter@tu-berlin.de
%LICENSE: free to use at your own risk. Kudos appreciated.

classdef LightCrafter < handle
    
    properties %(Hidden)
        tcpConnection
    end
    
    methods

        %constructor
        function obj = LightCrafter()
        end

        function connect( obj )
            obj.tcpConnection = tcpip( '192.168.1.100', 21845 )
            fopen( obj.tcpConnection )
        end

        function disconnect( obj )
            fclose( obj.tcpConnection )
        end

        function header = createHeader( obj )
            header = uint8( zeros( 6, 1 ) );
        end

        function modifiedHeader = appendPayloadLengthToHeaderForPayload( obj, header, payload )
            payloadLength = length( payload );
            payloadLengthMSB = floor( payloadLength / 256 );
            payloadLengthLSB = mod( payloadLength, 256 );

            header( 5 ) = uint8( payloadLengthLSB ); %payloadLength LSB
            header( 6 ) = uint8( payloadLengthMSB ); %payloadLength MSB

            modifiedHeader = header;
        end

        function modifiedPacket = appendChecksum( obj, packet )
            checksum = mod( sum( packet ), 256 );
            modifiedPacket = [ packet; checksum ];
        end

        %%Cem 10/23/2012
        function getVersion( obj,Version, connection )

            if (~ischar(Version) && (length(Version)~=2))
                disp('Version must be a 2 digit hex string 00, 10, or 20')
                return;
            end

            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '00' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            header( 5 ) = uint8( hex2dec( '01' ) ); %payloadLength LSB
            header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( hex2dec( Version ) ); %payload
            packet = obj.appendChecksum( [ header; payload ] );
            %packet
            obj.sendData( packet, connection );
        end

        %%Cem 10/23/2012
        function setDisplayMode( obj,DisplayMode, connection )  % 00, 01, 02, 03, 04 = static image, internal test pattern, hdmi, reserved, pattern sequence display

            if (~ischar(DisplayMode) && (length(DisplayMode)~=2))
                disp('Display mode must be a 2 digit hex string in range 00 to 04')  
                return;
            end

            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '01' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            header( 5 ) = uint8( hex2dec( '01' ) ); %payloadLength LSB
            header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( hex2dec( DisplayMode ) ); %payload
            packet = obj.appendChecksum( [ header; payload ] );
            %packet
            obj.sendData( packet, connection );

        end
        


        %%Cem 10/23/2012
        function setPatternSequence( obj,bitDepth, noPatterns, incInv, trigType, trigDelay, trigPeriod, exposureTime, LEDType, connection )

%             if (~ischar(bitDepth) && (length(bitDepth)~=2))
%                 disp('Pattern bit depth must be 01 to 08')
%                 return;
%             end
% 
%             if (~ischar(noPatterns) && (length(noPatterns)~=2))
%                 disp('Number of Patterns must be 01 to 60 (96 dec)')
%                 return;
%             end
% 
%             if (~ischar(incInv) && (length(incInv)~=2))
%                 disp('Include inverted patterns 00: every pattern, 01: each pattern followed by its inverted pattern')
%                 return;
%             end
% 
%             if (~ischar(trigType) && (length(trigType)~=2))
%                 disp('Input trigger type 00: Command trigger, 01: Auto, 02:External (+ve), 03: External(-ve), 04: Camera (+ve), 05: Camera (-ve), 06: External + Exposure ')
%                 return;
%             end
% 
%             if (~ischar(trigDelay) && (length(trigDelay)~=2))
%                 disp('Trigger delay in microseconds ')
%                 return;
%             end
% 
%             if (~ischar(trigPeriod) && (length(trigPeriod)~=2))
%                 disp('Trig period in micro seconds (only on Auto trigger mode)')
%                 return;
%             end
% 
%             if (~ischar(exposureTime) && (length(exposureTime)~=8))
%                 disp('Exposure time in micro seconds')
%                 return;
%             end
% 
%             if (~ischar(LEDType) && (length(LEDType)~=8))
%                 disp('LED type 00:red, 01: Green, 02: Blue')
%                 return;
%             end
            
            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '04' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '00' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            payload = [[uint8(hex2dec( bitDepth)); uint8(hex2dec( noPatterns )); ... 
                    uint8(hex2dec( incInv )); uint8(hex2dec( trigType ))]; ...
                    typecast(uint32(hex2dec(trigDelay)), 'uint8').'; ...
                    typecast(uint32(hex2dec(trigPeriod)), 'uint8').'; ...
                    typecast(uint32(hex2dec(exposureTime)), 'uint8').'; ...
                    [uint8(hex2dec( LEDType))] ];
            disp(payload)

            header = obj.appendPayloadLengthToHeaderForPayload(header, payload);
            packet = obj.appendChecksum( [ header; payload ] );
            %packet
            obj.sendData( packet, connection );

        end
        
        
        % added by jacob pierce 2.6.17
        function setPattern(obj, pattern_num, imageData, connection )
            
            % send an initial message containing the pattern number
            % disp(uint8(pattern_num))
            if (1)
                % disp(uint8( hex2dec( '05' ) ))
                header = obj.createHeader();
                header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
                header( 2 ) = uint8( hex2dec( '04' ) ); %CMD1
                header( 3 ) = uint8( hex2dec( '01' ) ); %CMD2
                header( 4 ) = uint8( hex2dec( '01' ) );
                payload = uint8(hex2dec(pattern_num)); %payload
                header = obj.appendPayloadLengthToHeaderForPayload( header, payload );
                packet = obj.appendChecksum( [ header; payload ] );
                obj.sendData( packet, connection );
            end

            % now send the rest of the message. first break into chunks
            MAX_PAYLOAD_SIZE = 65535;
            numberOfChunks = ceil( length( imageData ) / 65535 );
            chunkArray = cell( numberOfChunks, 1 );
            for i = 1 : numberOfChunks
                currentLength = length( imageData );
                if( currentLength > MAX_PAYLOAD_SIZE )
                    chunkArray{ i } = imageData( 1 : MAX_PAYLOAD_SIZE );
                    imageData = imageData( MAX_PAYLOAD_SIZE + 1 : end );
                else
                    chunkArray{ i } = imageData( 1 : end );
                end
            end

            for currentChunkIndex = 1 : numberOfChunks
    
                currentChunk = chunkArray{ currentChunkIndex };

                header = obj.createHeader();
                header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
                header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
                header( 3 ) = uint8( hex2dec( '05' ) ); %CMD2
                header = obj.appendPayloadLengthToHeaderForPayload( header, currentChunk );

                %append flag
                if( numberOfChunks == 1 )
                    header( 4 ) = uint8( hex2dec( '02' ) ); %flags
                else
                    if( currentChunkIndex == numberOfChunks )
                        header( 4 ) = uint8( hex2dec( '03' ) ); %flags
                    else
                        header( 4 ) = uint8( hex2dec( '02' ) ); %flags
                    end
                end

                packet = obj.appendChecksum( [ header; currentChunk ] );
                obj.sendData( packet, connection );
            end
        end

        

        %%Cem 10/23/2012
        function SSPatternSequence(obj, StartStop, connection )
            % obj.setDisplayModePattern( connection );

            if (~ischar(StartStop) && (length(StartStop)~=2))
                disp('StartStop must be 00: Start, 01: Stop pattern sequence')
                return;
            end

            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '04' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '02' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            % header( 5 ) = uint8( hex2dec( '01' ) ); %payloadLength LSB
            % header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( hex2dec( StartStop ) ); %payload
            header = obj.appendPayloadLengthToHeaderForPayload( header, payload );
            packet = obj.appendChecksum( [ header; payload ] );
            obj.sendData( packet, connection );
        end
        
        
        function displayPattern (obj, pattern_num)
            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '04' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '05' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
%             header( 5 ) = uint8( hex2dec( '01' ) ); %payloadLength LSB
%             header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( hex2dec( pattern_num ) ); %payload
            header = obj.appendPayloadLengthToHeaderForPayload( header, payload );
            packet = obj.appendChecksum( [ header; payload ] );
            obj.sendData( packet, obj.tcpConnection );           
        end
        
        

        %%Cem 10/23/2012
        function setLEDCurrent( obj,redCurrent, greenCurrent, blueCurrent, connection )

            if (~ischar(redCurrent) && (length(redCurrent)~=2))
                disp('Red LED curent must be 00 to 400 (1024 dec)')
                return;
            end

            if (~ischar(greenCurrent) && (length(greenCurrent)~=2))
                disp('Green LED curent must be 00 to 400 (1024 dec)')
                return;
            end

            if (~ischar(blueCurrent) && (length(blueCurrent)~=2))
                disp('Green LED curent must be 00 to 400 (1024 dec)')
                return;
            end

            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '04' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            header( 5 ) = uint8( hex2dec( '05' ) ); %payloadLength LSB
            header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( [ hex2dec( redCurrent ); hex2dec( greenCurrent );hex2dec( blueCurrent ) ] ); %payload
            packet = obj.appendChecksum( [ header; payload ] );
            %packet
            obj.sendData( packet, connection );

        end

        function setDisplayModeStatic( obj, connection )
            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '01' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            header( 5 ) = uint8( hex2dec( '01' ) ); %payloadLength LSB
            header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( hex2dec( '00' ) ); %payload
            packet = obj.appendChecksum( [ header; payload ] );
            %packet
            obj.sendData( packet, connection );

        end

        function setDisplayModeInternalPattern( obj, connection )

            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '01' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            header( 5 ) = uint8( hex2dec( '01' ) ); %payloadLength LSB
            header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( hex2dec( '01' ) ); %payload
            packet = obj.appendChecksum( [ header; payload ] );
            %packet
            obj.sendData( packet, connection );

        end
        
        function setDisplayModePattern( obj, connection )

            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '01' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            header( 5 ) = uint8( hex2dec( '01' ) ); %payloadLength LSB
            header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( hex2dec( '04' ) ); %payload
            packet = obj.appendChecksum( [ header; payload ] );
            %packet
            obj.sendData( packet, connection );

        end

        function setInternalPattern( obj, pattern, connection )

            obj.setDisplayModeInternalPattern( connection );

            if ( ~ischar( pattern ) && ( length(pattern) ~= 2 ) )
                disp('pattern must be a 2 digit hex string in range 00 to 0D')
                return;
            end

            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '03' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            header( 5 ) = uint8( hex2dec( '01' ) ); %payloadLength LSB
            header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( hex2dec( pattern ) ); %payload
            packet = obj.appendChecksum( [ header; payload ] );
            %packet
            obj.sendData( packet, connection );

        end

        function setStaticColor( obj, R, G, B, connection )

            obj.setDisplayModeStatic( connection );

            if ( ~ischar( R ) && ( length(R) ~= 2 ) )
                disp('R must be a 2 digit hex string in range 00 to FF')
                return;
            end
            if ( ~ischar( G ) && ( length(G) ~= 2 ) )
                disp('G must be a 2 digit hex string in range 00 to FF')
                return;
            end
            if ( ~ischar( B ) && ( length(B) ~= 2 ) )
                disp('B must be a 2 digit hex string in range 00 to FF')
                return;
            end

            header = obj.createHeader();
            header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
            header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
            header( 3 ) = uint8( hex2dec( '06' ) ); %CMD2
            header( 4 ) = uint8( hex2dec( '00' ) ); %flags
            header( 5 ) = uint8( hex2dec( '04' ) ); %payloadLength LSB
            header( 6 ) = uint8( hex2dec( '00' ) ); %payloadLength MSB
            payload = uint8( [ hex2dec( '00' ); hex2dec( R ); hex2dec( G ); hex2dec( B ) ] ); %payload
            packet = obj.appendChecksum( [ header; payload ] );
            %packet
            obj.sendData( packet, connection );

        end

        function setBMPImage( obj, imageData, connection )

            obj.setDisplayModeStatic( connection );

            MAX_PAYLOAD_SIZE = 65535;
            numberOfChunks = ceil( length( imageData ) / 65535 );
            chunkArray = cell( numberOfChunks, 1 );
            for i = 1 : numberOfChunks
                currentLength = length( imageData );
                if( currentLength > MAX_PAYLOAD_SIZE )
                    chunkArray{ i } = imageData( 1 : MAX_PAYLOAD_SIZE );
                    imageData = imageData( MAX_PAYLOAD_SIZE + 1 : end );
                else
                    chunkArray{ i } = imageData( 1 : end );
                end
            end

            for currentChunkIndex = 1 : numberOfChunks

                currentChunk = chunkArray{ currentChunkIndex };

                header = obj.createHeader();
                header( 1 ) = uint8( hex2dec( '02' ) );	%packet type
                header( 2 ) = uint8( hex2dec( '01' ) ); %CMD1
                header( 3 ) = uint8( hex2dec( '05' ) ); %CMD2
                header = obj.appendPayloadLengthToHeaderForPayload( header, currentChunk );

                %append flag
                if( numberOfChunks == 1 )
                    header( 4 ) = uint8( hex2dec( '00' ) ); %flags
                else
                    if( currentChunkIndex == 1 )
                        header( 4 ) = uint8( hex2dec( '01' ) ); %flags
                    elseif( currentChunkIndex == numberOfChunks )
                        header( 4 ) = uint8( hex2dec( '03' ) ); %flags
                    else
                        header( 4 ) = uint8( hex2dec( '02' ) ); %flags
                    end
                end

                packet = obj.appendChecksum( [ header; currentChunk ] );
                obj.sendData( packet, connection );
            end
        disp 'INFO: Set BMP Image'
        end

        function sendData( obj, packet, connection )

            %limit packet size
            MAX_SIZE = 512;
            buffer = packet;
            while (~isnan(buffer))
                if( length(buffer) > MAX_SIZE )
                    currentPacket = buffer( 1 : MAX_SIZE );
                    buffer = buffer( MAX_SIZE + 1 : end );
                else
                    currentPacket = buffer( 1 : end );
                    buffer = NaN;
                end
                %fwrite( obj.tcpConnection, currentPacket ) ;
                fwrite( connection, currentPacket ) ;
                % disp('wrote some data');
                %disp( currentPacket );
            end
        end

    end % methods

end % classdef