//
//  AFNetworkExtend.swift
//

import UIKit
import AFNetworking

public enum AFUploadType {
    case Audio
    case Video
}

private class AFUploadModel: NSObject {
    
    private(set) var type: AFUploadType
    private(set) var data: Data
    
    init(type: AFUploadType, data: Data) {
        self.type = type
        self.data = data
        super.init()
    }
    
}

public class AFNetworkExtend: NSObject {
    
    public enum HttpMethod: Int {
        case Get = 0
        case Post
        case Delete
        case Put
    }
    
    public enum RequestType: Int {
        case JSON = 0
        case PlainText
    }
    
    public enum ResponseType: Int {
        case JSON = 0
        case XML
        case Data
    }
    
    public typealias ProgressBlock = (Int64, Int64) -> ()
    public typealias SuccessBlock = (Any?) -> ()
    public typealias FailureBlock = (Any?) -> ()
    
    public static var baseUrl: String = ""
    public static var httpHeaders: [String: String] = [:]
    public static var requestType: RequestType = .JSON
    public static var responseType: ResponseType = .JSON
    public static var timeoutInterval: TimeInterval = 10.0
    
    public static func addHttpHeader(_ value: String?, key: String) {
        httpHeaders[key] = value
    }
    
    public static func removeHttpHeader(_ key: String) {
        httpHeaders.removeValue(forKey: key)
    }
    
    private static var tasks: [URLSessionTask] = []
    
    private static var manager: AFHTTPSessionManager {
        // 活动指示器
        AFNetworkActivityIndicatorManager.shared().isEnabled = true
        // 初始化
        var manager: AFHTTPSessionManager!
        if baseUrl.isEmpty {
            manager = AFHTTPSessionManager()
        }
        else {
            manager = AFHTTPSessionManager(baseURL: URL(string: baseUrl)!)
        }
        // 请求数据类型
        switch requestType {
        case .JSON:
            manager.requestSerializer = AFJSONRequestSerializer()
            break
        case .PlainText:
            manager.requestSerializer = AFHTTPRequestSerializer()
            break
        }
        // 返回数据类型
        switch responseType {
        case .JSON:
            manager.responseSerializer = AFJSONResponseSerializer()
            break
        case .XML:
            manager.responseSerializer = AFXMLParserResponseSerializer()
            break
        case .Data:
            manager.responseSerializer = AFHTTPResponseSerializer()
            break
        }
        // 添加HttpHeaders
        for key in httpHeaders.keys {
            manager.requestSerializer.setValue(httpHeaders[key], forHTTPHeaderField: key)
        }
        // 请求参数编码方式
        manager.requestSerializer.stringEncoding = String.Encoding.utf8.rawValue
        // 返回参数编码方式
        manager.responseSerializer.acceptableContentTypes = Set(["application/json", "text/html", "text/json", "text/plain", "text/javascript", "text/xml", "image/*"])
        // 最大并发量
        manager.operationQueue.maxConcurrentOperationCount = 5
        // 设置超时限制
        manager.requestSerializer.willChangeValue(forKey: "timeoutInterval")
        manager.requestSerializer.timeoutInterval = timeoutInterval
        manager.requestSerializer.didChangeValue(forKey: "timeoutInterval")
        return manager
    }
    
}

public extension AFNetworkExtend {
    // Get
    static func getWith(_ url: String, params: [String: Any] = [:], success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        requestWith(url, httpMethod: .Get, params: params, progress: nil, success: success, failure: failure)
    }
    // Post
    static func postWith(_ url: String, params: [String: Any], success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        requestWith(url, httpMethod: .Post, params: params, progress: nil, success: success, failure: failure)
    }
    // Delete
    static func deleteWith(_ url: String, params: [String: Any] = [:], success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        requestWith(url, httpMethod: .Delete, params: params, progress: nil, success: success, failure: failure)
    }
    // Put
    static func putWith(_ url: String, params: [String: Any], success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        requestWith(url, httpMethod: .Put, params: params, progress: nil, success: success, failure: failure)
    }
    
    private static func requestWith(_ url: String, httpMethod: HttpMethod, params: [String: Any] = [:], progress: ProgressBlock? = nil, success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        var task: URLSessionTask?
        if httpMethod == .Get {
            task = manager.get(url, parameters: params, headers: nil, progress: { downloadProgress in
                if progress != nil {
                    progress?(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount)
                }
            }, success: { (task, response) in
                successWith(response, success: success)
                tasks.removeAll(where: {$0 == task})
            }, failure: { (task, error) in
                failureWith(error, failure: failure)
                tasks.removeAll(where: {$0 == task})
            })
        }
        else if httpMethod == .Post {
            task = manager.post(url, parameters: params, headers: nil, progress: { downloadProgress in
                if progress != nil {
                    progress?(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount)
                }
            }, success: { (task, response) in
                successWith(response, success: success)
                tasks.removeAll(where: {$0 == task})
            }, failure: { (task, error) in
                failureWith(error, failure: failure)
                tasks.removeAll(where: {$0 == task})
            })
        }
        else if httpMethod == .Delete {
            task = manager.delete(url, parameters: params, headers: nil, success: { (task, response) in
                successWith(response, success: success)
                tasks.removeAll(where: {$0 == task})
            }, failure: { (task, error) in
                failureWith(error, failure: failure)
                tasks.removeAll(where: {$0 == task})
            })
        }
        else if httpMethod == .Put {
            task = manager.put(url, parameters: params, headers: nil, success: { (task, response) in
                successWith(response, success: success)
                tasks.removeAll(where: {$0 == task})
            }, failure: { (task, error) in
                failureWith(error, failure: failure)
                tasks.removeAll(where: {$0 == task})
            })
        }
        task?.resume()
        if task != nil {
            tasks.append(task!)
        }
    }
    
}

public extension AFNetworkExtend {
    // 上传图片
    static func uploadImageWith(_ url: String, image: UIImage, params: [String: Any] = [:], progress: ProgressBlock? = nil, success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        return uploadImageWith(url, photos: [image], params: params, progress: progress, success: success, failure: failure)
    }
    // 上传多张图片
    static func uploadImageWith(_ url: String, photos: [UIImage], params: [String: Any] = [:], progress: ProgressBlock? = nil, success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        let task = manager.post(url, parameters: params, headers: nil) { formData in
            for image in photos {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMddHHmmss"
                let timeStr = formatter.string(from: Date())
                let fileName = timeStr + ".png"
                if let imageData = compressImageWith(image) {
                    formData.appendPart(withFileData: imageData, name: "file", fileName: fileName, mimeType: "image/jpeg")
                }
            }
        } progress: { uploadProgress in
            if progress != nil {
                progress?(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount)
            }
        } success: { (task, response) in
            successWith(response, success: success)
            tasks.removeAll(where: {$0 == task})
        } failure: { (task, error) in
            failureWith(error, failure: failure)
            tasks.removeAll(where: {$0 == task})
        }
        task?.resume()
        if task != nil {
            tasks.append(task!)
        }
    }
    
}

public extension AFNetworkExtend {
    // 上传音视频
    static func uploadDataWith(_ url: String, data: Data, params: [String: Any] = [:], fileType: AFUploadType, progress: ProgressBlock? = nil, success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        let model = AFUploadModel(type: fileType, data: data)
        return submitFormWith(url, params: params, uploadFiles: [model], progress: progress, success: success, failure: failure)
    }
    
    private static func submitFormWith(_ url: String, params: [String: Any] = [:], uploadFiles: [AFUploadModel], progress: ProgressBlock? = nil, success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        let manager = manager
        manager.requestSerializer.timeoutInterval = 60.0
        let task = manager.post(url, parameters: params, headers: nil) { formData in
            for model in uploadFiles {
                let fileData = model.data
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMddHHmmss"
                let timeStr = formatter.string(from: Date())
                switch model.type {
                case .Audio:
                    let fileName = timeStr + ".mp3"
                    formData.appendPart(withFileData: fileData, name: "file", fileName: fileName, mimeType: "audio/mpeg")
                    break
                case .Video:
                    let fileName = timeStr + ".mp4"
                    formData.appendPart(withFileData: fileData, name: "file", fileName: fileName, mimeType: "video/mp4")
                    break
                }
            }
        } progress: { uploadProgress in
            if progress != nil {
                progress?(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount)
            }
        } success: { task, response in
            successWith(response, success: success)
            tasks.removeAll(where: {$0 == task})
        } failure: { task, error in
            failureWith(error, failure: failure)
            tasks.removeAll(where: {$0 == task})
        }
        task?.resume()
        if task != nil {
            tasks.append(task!)
        }
    }
    
}

public extension AFNetworkExtend {
    // 下载文件
    static func downloadWith(_ url: String, progress: ProgressBlock? = nil, success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        let request = URLRequest(url: URL(string: url)!)
        var task: URLSessionTask?
        task = manager.downloadTask(with: request) { downloadProgress in
            if progress != nil {
                progress?(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount)
            }
        } destination: { (targetPath, response) in
            let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsDirectoryURL.appendingPathComponent(response.suggestedFilename!)
        } completionHandler: { (response, filePath, error ) in
            if error == nil {
                success(filePath)
            }
            else {
                failureWith(error!, failure: failure)
            }
            tasks.removeAll(where: {$0 == task!})
        }
        task?.resume()
        if task != nil {
            tasks.append(task!)
        }
    }
    
}

public extension AFNetworkExtend {
    
    static func cancelAllRequest() {
        for task in tasks {
            if task.isKind(of: URLSessionTask.self) {
                task.cancel()
            }
        }
        tasks.removeAll()
    }
    
    static func cancelRequestWith(_ url: String) {
        for task in tasks {
            if task.isKind(of: URLSessionTask.self),
               task.currentRequest?.url?.absoluteString.hasSuffix(url) == true {
                task.cancel()
                tasks.removeAll(where: {$0 == task})
            }
        }
    }
    
}

private extension AFNetworkExtend {
    
    static func successWith(_ response: Any?, success: SuccessBlock) {
        guard let responseData = response else {
            success(response)
            return
        }
        if responseData is Data {
            let data = responseData as! Data
            guard let dic = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                success(response)
                return
            }
            success(dic)
        }
        else {
            success(response)
        }
    }
    
    static func failureWith(_ error: Error, failure: FailureBlock) {
        let nserror = error as NSError
        let errorData = nserror.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]
        if errorData == nil {
            failure([
                "code": nserror.code,
                "error": nserror.localizedDescription
            ])
        }
        else {
            guard let data = errorData as? Data,
                  let dic = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                      failure([
                          "code": nserror.code,
                          "error": nserror.localizedDescription
                      ])
                return
            }
            failure(dic)
        }
    }
    // 压缩图片
    static func compressImageWith(_ image: UIImage?) -> Data? {
        guard let data = image?.jpegData(compressionQuality: 1.0) else {
            return nil
        }
        if data.count > 100 * 1024 {
            if data.count > 1024 * 1024 {
                return image?.jpegData(compressionQuality: 0.1)
            }
            else if data.count > 512 * 1024 {
                return image?.jpegData(compressionQuality: 0.5)
            }
            else if data.count > 200 * 1024 {
                return image?.jpegData(compressionQuality: 0.9)
            }
        }
        return data
    }
    
}
