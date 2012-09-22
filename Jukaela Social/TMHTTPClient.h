//
//  TMHTTPClient.h
//  ZummZumm
//
//  Created by Tony Million on 26/05/2012.
//  Copyright (c) 2012 OmniTyke. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Specifies the method used to encode parameters into request body. 
 */
typedef enum {
    TMFormURLParameterEncoding,
    TMJSONParameterEncoding,
} TMHTTPClientParameterEncoding;

@protocol TMMultipartFormData;
@class TMHTTPRequest;

#import "TMHTTPRequest.h"


@interface TMHTTPClient : NSObject

/**
 The url used as the base for paths specified in methods such as `getPath:parameteres:success:failure`
 */
@property (readonly, nonatomic, strong) NSURL *baseURL;

/**
 The string encoding used in constructing url requests. This is `NSUTF8StringEncoding` by default.
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

@property (nonatomic, assign) TMHTTPClientParameterEncoding parameterEncoding;


///---------------------------------------------
/// @name Creating and Initializing HTTP Clients
///---------------------------------------------

/**
 Creates and initializes an `AFHTTPClient` object with the specified base URL.
 
 @param url The base URL for the HTTP client. This argument must not be nil.
 
 @return The newly-initialized HTTP client
 */
+ (TMHTTPClient *)clientWithBaseURL:(NSURL *)url;

/**
 Initializes an `AFHTTPClient` object with the specified base URL.
 
 @param url The base URL for the HTTP client. This argument must not be nil.
 
 @discussion This is the designated initializer.
 
 @return The newly-initialized HTTP client
 */
- (id)initWithBaseURL:(NSURL *)url;

///----------------------------------
/// @name Managing HTTP Header Values
///----------------------------------

/**
 Returns the value for the HTTP headers set in request objects created by the HTTP client.
 
 @param header The HTTP header to return the default value for
 
 @return The default value for the HTTP header, or `nil` if unspecified
 */
- (NSString *)defaultValueForHeader:(NSString *)header;

/**
 Sets the value for the HTTP headers set in request objects made by the HTTP client. If `nil`, removes the existing value for that header.
 
 @param header The HTTP header to set a default value for
 @param value The value set as default for the specified header, or `nil
 */
- (void)setDefaultHeader:(NSString *)header value:(NSString *)value;

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and path.
 
 If the HTTP method is `GET`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL. Otherwise, the parameters will be encoded according to the value of the `parameterEncoding` property, and set as the request body.
 
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
 
 @return An `NSMutableURLRequest` object 
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method 
                                      path:(NSString *)path 
                                parameters:(NSDictionary *)parameters;

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and path, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block. See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2
 
 @param method The HTTP method for the request. Must be either `POST`, `PUT`, or `DELETE`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol. This can be used to upload files, encode HTTP body as JSON or XML, or specify multiple values for the same parameter, as one might for array values.
 
 @discussion The multipart form data is constructed synchronously in the specified block, so in cases where large amounts of data are being added to the request, you should consider performing this method in the background. Likewise, the form data is constructed in-memory, so it may be advantageous to instead write parts of the form data to a file and stream the request body using the `HTTPBodyStream` property of `NSURLRequest`.
 
 @warning An exception will be raised if the specified method is not `POST`, `PUT` or `DELETE`.
 
 @return An `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <TMMultipartFormData> formData))block;

///---------------------------
/// @name Making HTTP Requests
///---------------------------

- (TMHTTPRequest*)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(TMHTTPRequest *operation, id responseObject))success
        failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure;

- (TMHTTPRequest*)postPath:(NSString *)path 
      parameters:(NSDictionary *)parameters 
         success:(void (^)(TMHTTPRequest *operation, id responseObject))success
         failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure;

- (TMHTTPRequest*)putPath:(NSString *)path 
     parameters:(NSDictionary *)parameters 
        success:(void (^)(TMHTTPRequest *operation, id responseObject))success
        failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure;

- (TMHTTPRequest*)deletePath:(NSString *)path 
        parameters:(NSDictionary *)parameters 
           success:(void (^)(TMHTTPRequest *operation, id responseObject))success
           failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure;

- (TMHTTPRequest*)patchPath:(NSString *)path
       parameters:(NSDictionary *)parameters 
          success:(void (^)(TMHTTPRequest *operation, id responseObject))success
          failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure;

- (TMHTTPRequest *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
										   success:(void (^)(TMHTTPRequest *operation, id responseObject))success
										   failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure;

- (void)enqueueHTTPRequestOperation:(TMHTTPRequest *)request;
- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method path:(NSString *)path;

@end











/**
 The `AFMultipartFormData` protocol defines the methods supported by the parameter in the block argument of `multipartFormRequestWithMethod:path:parameters:constructingBodyWithBlock:`.
 
 @see `AFHTTPClient -multipartFormRequestWithMethod:path:parameters:constructingBodyWithBlock:`
 */
@protocol TMMultipartFormData

/**
 Appends HTTP headers, followed by the encoded data and the multipart form boundary.
 
 @param headers The HTTP headers to be appended to the form data.
 @param body The data to be encoded and appended to the form data.
 */
- (void)appendPartWithHeaders:(NSDictionary *)headers body:(NSData *)body;

/**
 Appends the HTTP headers `Content-Disposition: form-data; name=#{name}"`, followed by the encoded data and the multipart form boundary.
 
 @param data The data to be encoded and appended to the form data.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 */
- (void)appendPartWithFormData:(NSData *)data name:(NSString *)name;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.
 
 @param data The data to be encoded and appended to the form data.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param mimeType The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) For a list of valid MIME types, see http://www.iana.org/assignments/media-types/. This parameter must not be `nil`.
 @param filename The filename to be associated with the specified data. This parameter must not be `nil`.
 */
- (void)appendPartWithFileData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{generated filename}; name=#{name}"` and `Content-Type: #{generated mimeType}`, followed by the encoded file data and the multipart form boundary.
 
 @param fileURL The URL corresponding to the file whose content will be appended to the form.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 
 @return `YES` if the file data was successfully appended, otherwise `NO`.
 
 @discussion The filename and MIME type for this data in the form will be automatically generated, using `NSURLResponse` `-suggestedFilename` and `-MIMEType`, respectively.
 */
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name error:(NSError **)error;

/**
 Appends encoded data to the form data.
 
 @param data The data to be encoded and appended to the form data.
 */
- (void)appendData:(NSData *)data;

/**
 Appends a string to the form data.
 
 @param string The string to be encoded and appended to the form data.
 */
- (void)appendString:(NSString *)string;

@end


