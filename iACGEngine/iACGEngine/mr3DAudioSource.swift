//
//  mr3DAudioSource.swift
//  iACGEngine
//
//  Created by Martin.Ren on 16/2/6.
//  Copyright © 2016年 Martin.Ren. All rights reserved.
//

import Foundation
import OpenAL
import CoreAudio
import AudioToolbox

public class mr3DAudioSource {
    
    //begin private member
    private var sourceData          : UnsafeMutablePointer<Void> //is a ALvoid
    private var sourceFormat        : ALenum
    private var sourceSize          : ALsizei
    private var sourceFreq          : ALsizei
    private var sourceId            : ALuint
    private var sourceBuffId        : ALuint
    private var sourceDuration      : Float64

    public  var identifier          : String
    public  var filePath            : String
    public  var duration            : Float
    
    private var _isLoop             : Bool = false
    public  var  isLoop             : Bool {
        
        get {
            
            var isLoopMode:ALint = AL_FALSE;
            alGetSourcei(sourceBuffId, AL_LOOPING, &isLoopMode)
            
            _isLoop = isLoopMode == AL_FALSE ? false : true
            
            if (isLoopMode == AL_FALSE)
            {
                return false;
            }
            
            if (isLoopMode == AL_TRUE)
            {
                return true;
            }
            
            return false;
        }
        
        set {
            _isLoop = isLoop
            alSourcei(sourceBuffId, AL_LOOPING, isLoop ? AL_TRUE : AL_FALSE)
        }
    }
    
    private var _currentSecOffSet   : ALfloat = 0.0
    public  var  currentSecOffSet   : ALfloat {
        
        get {
            
            var currOffSetSec:ALfloat = 0.0
            
            alGetSourcef(sourceId, AL_SEC_OFFSET, &currOffSetSec)
            
            _currentSecOffSet = currOffSetSec
            
            return _currentSecOffSet
        }
        
        set {
            
            _currentSecOffSet = currentSecOffSet
            
            alSourcef(sourceId, AL_SEC_OFFSET, _currentSecOffSet)
            
            return
        }
    }
    
    private var _status             : MR3DAUDIO_ENGINE_SOURCE_STATUS = MR3DAUDIO_ENGINE_SOURCE_STATUS.UNREADY
    public  var  status             : MR3DAUDIO_ENGINE_SOURCE_STATUS {
        
        get {
            var sourceState:ALint = -1
            
            alGetSourcei(sourceId, AL_SOURCE_STATE, &sourceState)
            
            if (sourceState == AL_PLAYING)
            {
                return MR3DAUDIO_ENGINE_SOURCE_STATUS.PLAYING
            }
            
            if (sourceState == AL_PAUSED)
            {
                return MR3DAUDIO_ENGINE_SOURCE_STATUS.PAUSE
            }
            
            if (sourceState == AL_STOPPED)
            {
                return MR3DAUDIO_ENGINE_SOURCE_STATUS.STOPED
            }
            
            if (sourceState == AL_INITIAL)
            {
                return MR3DAUDIO_ENGINE_SOURCE_STATUS.SUCCESS
            }
            
            return MR3DAUDIO_ENGINE_SOURCE_STATUS.UNREADY
        }
        
        set {
            NSLog("you can't set audio source state in the all mr3DAudioEngine codes and calling.")
        }
    }
    
    private var _position           : mr3DAudioPosition = mr3DAudioPosition(x: 0, y: 0, z: 0)
    public  var  position           : mr3DAudioPosition {
        
        get {
            
            return _position
            
        }
        
        set {
            
            _position = position;
            
            let alPostion:[ALfloat] = [position.x, position.y, position.z]
            
            alListenerfv(AL_POSITION, alPostion);
            
        }
    }
    
    deinit {
//        alSourceRemoveStateNotification(sourceId, AL_SOURCE_STATE, MXAE_SourceNotification_SourceStateChanged, NULL);
//        alSourceRemoveStateNotification(sourceId, AL_QUEUE_HAS_LOOPED, MXAE_SourceNotification_SourceLooped,NULL);
        
        alDeleteSources(1, &sourceId);
        alDeleteBuffers(1, &sourceBuffId);
    }
    
    public init (identifier aIdentifier : String, path aPath : String,  position aPosition : mr3DAudioPosition, loopMode isLoop : Bool) {
        
        self.identifier = aIdentifier
        self.filePath = aPath
        self._position = aPosition
        self.duration = 0.0
        
        //private member init
        self.sourceData = nil
        self.sourceFormat = 0
        self.sourceSize = 0
        self.sourceFreq = 0
        self.sourceId = 0
        self.sourceBuffId = 0
        self.sourceDuration = 0
        
        
        let fileURL : NSURL = NSURL(fileURLWithPath: aPath)
        
        let audioInfo = self.getOpenALAudioData(fileURL: fileURL)
        
        sourceData = audioInfo.sourceData
        
        let fileID:AudioFileID = self.openAudioFile(fileURL)
        
        var fileSize : UInt32 = self.audioFileSize(fileID)
        
        let outData : UnsafeMutablePointer<Void> = malloc(Int(fileSize))
        
        var thePropSize:UInt32 = UInt32(sizeof(UInt64));
        
        var thenDuration : Float64 = 0;
        
        var result = AudioFileReadBytes(fileID, false, 0, &fileSize, outData)
        
        if ( result != noErr ) {
            NSLog("cannot load audio: %@", fileURL)
        }
        
        result = AudioFileGetProperty(fileID, kAudioFilePropertyEstimatedDuration, &thePropSize, &thenDuration)
        
        self.sourceDuration = thenDuration;
        
        AudioFileClose(fileID);
        
        //create buffers
        alGenBuffers(1, &sourceBuffId);
        
        //此处无法解决立体声混音效果，如果使用 MONO16 可能导致失去立体声的效果。导致音效变差。
        //如果使用 STEREO16 会导致无法使用混音，解决方案是，通过算法取出左右声道，在模拟两个声源。
        alBufferData(sourceBuffId, AL_FORMAT_MONO16, sourceData, sourceSize, sourceFreq * 2);
        //        alBufferData(sourceBuffId, AL_FORMAT_STEREO16, sourceData, sourceSize, sourceFreq);
        
        //create sourceid
        alGenSources(1, &sourceId);
        alSourcei(sourceId, AL_BUFFER, Int32(sourceBuffId));
        
        if (outData == nil)
        {
            free(outData);
        }
        
        //增加通知
//        let currALCcontext = alcGetCurrentContext();
//        let currDevice     = alcGetContextsDevice(currALCcontext)
    }
    
    private func openAudioFile( fileURL : NSURL ) -> (AudioFileID) {
        var outAFID : AudioFileID = nil
        let result = AudioFileOpenURL(fileURL, AudioFilePermissions.ReadPermission, 0, &outAFID)
    
        if (result != noErr)
        {
            NSLog("cannot openf file: %@",filePath)
        }
        
        return outAFID;
    }
    
    private func audioFileSize(fileDescriptor : AudioFileID) -> (UInt32) {
        var outDataSize : UInt32 = 0
        var thePropSize : UInt32 = UInt32(sizeof(UInt64))
        
        let result = AudioFileGetProperty(fileDescriptor, kAudioFilePropertyAudioDataByteCount, &thePropSize, &outDataSize)
        
        if( result != noErr ) {
            NSLog("cannot find file size")
        }
        
        return outDataSize;
    }

    
    private func getOpenALAudioData(fileURL aURL : NSURL) -> (sourceData : UnsafeMutablePointer<Void>, sourceSizei : ALsizei, sourceFormat : ALenum, sourceFreq:ALsizei) {
        
        var err                         : OSStatus = noErr
        var theFileLengthInFrames       : UInt32 = 0
        var theFileFormat               : AudioStreamBasicDescription = AudioStreamBasicDescription()
        var theOutputFormat             : AudioStreamBasicDescription = AudioStreamBasicDescription()
        var thePropertySize             : UInt32 = UInt32(sizeof(AudioStreamBasicDescription))
        var theData                     : UnsafeMutablePointer<Void> = nil
        var extRef                      : ExtAudioFileRef = nil
        
        // Open a file with ExtAudioFileOpen()
        err = ExtAudioFileOpenURL(aURL, &extRef)
        
        if( err != noErr ) {
            
            NSLog("MyGetOpenALAudioData: ExtAudioFileOpenURL FAILED, Error = %d\n", err)
            
            if (extRef != nil) {
                ExtAudioFileDispose(extRef)
            }
            
            return (nil, 0, 0, 0)
        }
        
        // Get the audio data format
        err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileDataFormat, &thePropertySize, &theFileFormat)
        
        if( err != noErr ) {
            NSLog("MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileDataFormat) FAILED, Error = %d\n", err)
            
            if (extRef != nil) {
                ExtAudioFileDispose(extRef)
            }
            
            return (nil, 0, 0, 0)
        }
        
        if ( theFileFormat.mChannelsPerFrame > 2 ) {
            NSLog("MyGetOpenALAudioData - Unsupported Format, channel count is greater than stereo\n")
            
            if (extRef != nil) {
                ExtAudioFileDispose(extRef)
            }
            
            return (nil, 0, 0, 0)
        }
        
        // Set the client format to 16 bit signed integer (native-endian) data
        // Maintain the channel count and sample rate of the original source format
        
        theOutputFormat.mSampleRate = theFileFormat.mSampleRate
        theOutputFormat.mChannelsPerFrame = theFileFormat.mChannelsPerFrame
        theOutputFormat.mFormatID = kAudioFormatLinearPCM
        theOutputFormat.mBytesPerPacket = 2 * theOutputFormat.mChannelsPerFrame
        theOutputFormat.mFramesPerPacket = 1
        theOutputFormat.mBytesPerFrame = 2 * theOutputFormat.mChannelsPerFrame
        theOutputFormat.mBitsPerChannel = 16
        theOutputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
        
        // Set the desired client (output) data format
        err = ExtAudioFileSetProperty(extRef, kExtAudioFileProperty_ClientDataFormat, UInt32(sizeof(AudioStreamBasicDescription)), &theOutputFormat)
        if( err != noErr ) {
            NSLog("MyGetOpenALAudioData: ExtAudioFileSetProperty(kExtAudioFileProperty_ClientDataFormat) FAILED, Error = %d\n", err)
            
            if (extRef != nil) {
                ExtAudioFileDispose(extRef)
            }
            
            return (nil, 0, 0, 0)
        }
        
        // Get the total frame count
        thePropertySize = UInt32(sizeof(Int64))
        err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileLengthFrames, &thePropertySize, &theFileLengthInFrames)
        if( err != noErr) {
            NSLog("MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileLengthFrames) FAILED, Error = %d\n", err)
            
            if (extRef != nil) {
                ExtAudioFileDispose(extRef)
            }
            
            return (nil, 0, 0, 0)
        }
        
        // Read all the data into memory
        var theFramesToRead : UInt32 = theFileLengthInFrames
        let dataSize = Int(theFramesToRead * theOutputFormat.mBytesPerFrame)
        
        theData = UnsafeMutablePointer<Void>.alloc(dataSize)
        
        var theDataBuffer = AudioBufferList()
        theDataBuffer.mNumberBuffers = 1
        
        let tBuff = AudioBuffer.init(mNumberChannels: theOutputFormat.mChannelsPerFrame, mDataByteSize: UInt32(dataSize), mData: theData)
        theDataBuffer.mBuffers = tBuff
        
        // Read the data into an AudioBufferList
        err = ExtAudioFileRead(extRef, &theFramesToRead, &theDataBuffer)
        
        if(err != noErr) {
            // failure
            free (theData);
            theData = nil; // make sure to return NULL
            NSLog("MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %d\n", err)
        }
    
        // success
        let outDataSize = ALsizei.init(dataSize)
        let outDataFormat = ALenum.init((theOutputFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16)
        let outSampleRate = ALsizei.init(theOutputFormat.mSampleRate)
        
        // Dispose the ExtAudioFileRef, it is no longer needed
        if (extRef != nil) {
            ExtAudioFileDispose(extRef)
        }
        
        return (theData, outDataSize, outDataFormat, outSampleRate);
    }
    
    public func play() -> Void {
        alSourcePlay(sourceId);
    }
    
    public func stop() -> Void {
        alSourceStop(sourceId)
    }
    
    public func pause() -> Void {
        alSourcePause(sourceId)
    }
    
    public func resume() -> Void {
        self.play()
    }
}