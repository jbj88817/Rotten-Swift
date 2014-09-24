import UIKit
class MovieViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var networkErrorView: UIView!

    var movies:[NSDictionary]=[]

    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        networkErrorView.alpha = 0;
        networkErrorView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)

        self.refreshControl.attributedTitle = NSAttributedString(string: "Updating Movie List...")
        refreshControl.addTarget(self, action: "refreshMovieList", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)

        refreshMovieList()
    }

    func refreshMovieList() {
        var url = "http://api.rottentomatoes.com/api/public/v1.0/lists/movies/box_office.json?apikey=renaqk7mwx4v3vfj3g67xmcj&limit=20&country=us"
        var request = NSURLRequest(URL: NSURL(string:url))
        var session = NSURLSession.sharedSession()
        session.dataTaskWithRequest(request,
            completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in
                self.refreshControl.endRefreshing()
                if error == nil {

                    dispatch_async(dispatch_get_main_queue()) {
                        var object = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as NSDictionary
                        self.movies = object["movies"] as [NSDictionary]
                        self.tableView.reloadData()
                    }
                }
                else {
                    self.showNetworkError()
                }

        }).resume()
    }

    func showNetworkError() {
        dispatch_async(dispatch_get_main_queue()) {
            self.networkErrorView.alpha = 1
            let offset = 3.0
            UIView.animateWithDuration(offset, animations: {
                self.networkErrorView.alpha = 0
            })
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var movie = movies[indexPath.row]
        var movieId = movie["id"] as String
        performSegueWithIdentifier("detailView", sender: movieId)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "detailView") {
            let detailVC = segue.destinationViewController as DetailViewController
            detailVC.movieId = sender as String
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return movies.count
    }

    func fadeInImage (view :UIView) {
        let movieCell = view as MovieCell
        UIView.beginAnimations("fade in", context: nil)
        UIView.setAnimationDuration(1.5)
        movieCell.posterView.alpha = 1
        UIView.commitAnimations()
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("MovieCell") as MovieCell
        cell.accessoryType = UITableViewCellAccessoryType.None
        cell.posterView.alpha = 0

        var movie = movies[indexPath.row]
        cell.movieTitleLabel.text = movie["title"] as? String
        cell.synopsisLabel.text = movie["synopsis"] as? String

        var posters = movie["posters"] as NSDictionary
        var posterUrl = posters["thumbnail"] as String

        var image = SDImageCache.sharedImageCache().imageFromDiskCacheForKey(posterUrl)
        if image != nil {
            println("cached in disk")
            cell.posterView.image = image
            fadeInImage(cell)
            return cell
        }

        var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        cell.posterView.addSubview(activityIndicator)
        activityIndicator.center = cell.posterView.center
        activityIndicator.startAnimating()

        SDWebImageDownloader.sharedDownloader().downloadImageWithURL(NSURL(string: posterUrl), options: nil, progress: nil, completed: {[weak self] (image, data, error, finished) in
            activityIndicator.removeFromSuperview()
            if let wSelf = self {
                if image != nil {
                    cell.posterView.image = image
                    wSelf.fadeInImage(cell)
                    SDImageCache.sharedImageCache().storeImage(image, forKey: posterUrl, toDisk: true)
                }
            }
        })

        return cell
    }


}
