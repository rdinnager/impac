test_that("impac produces the same image", {

  set.seed(3717)

  imager::save.image(
    impac(
      function(i) imager::draw_circle(
        imager::imfill(500, 500, val = c(0, 0, 0, 0)),
        250, 250, radius = runif(1, 150, 250),
        color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
      ),
      width = 400, height = 400,
      max_images = 10, bg = "white",
      min_scale = 0.01
    )$image,
    path <- withr::local_tempfile(fileext = ".png")
  )

  expect_snapshot_file(path, "circles.png")

})

test_that("adding metadata works", {


  x <- impac(
      function(i) {
        ccol <- sample(grDevices::rainbow(100), 1)
        list(imager::draw_circle(
          imager::imfill(500, 500, val = c(0, 0, 0, 0)),
          250, 250, radius = runif(1, 150, 250),
          color = matrix(grDevices::col2rgb(ccol, alpha = TRUE), nrow = 1)
        ),
        color = ccol)},
      width = 400, height = 400,
      max_images = 10, bg = "white",
      min_scale = 0.01,
    )

  expect_identical(colnames(x$meta), c("x", "y", "scale", "image", "color"))
  expect_type(x$meta$color, "character")

})

test_that("different ways of specifying scaler work", {

  set.seed(1517)

  imager::save.image(
    img1 <- impac(
      function(i) imager::draw_circle(
        imager::imfill(500, 500, val = c(0, 0, 0, 0)),
        250, 250, radius = runif(1, 150, 250),
        color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
      ),
      width = 400, height = 400,
      max_images = 10, bg = "white",
      min_scale = 0.01,
      scaler = function() {
                    if(!.success & .try == 1 & .np < (.i * 0.5)) {
                      mscale <- min(.s)
                      c(.s, rep(mscale / 2, floor(1 / mscale)))
                    } else {
                      .s
                    }
                  }
    )$image,
    path <- withr::local_tempfile(fileext = ".png")
  )

  expect_snapshot_file(path, "circles2.png")

  set.seed(1517)

  imager::save.image(
    img2 <- impac(
      function(i) imager::draw_circle(
        imager::imfill(500, 500, val = c(0, 0, 0, 0)),
        250, 250, radius = runif(1, 150, 250),
        color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
      ),
      width = 400, height = 400,
      max_images = 10, bg = "white",
      min_scale = 0.01,
      scaler = function() {
                    if(!.success & .try == 1 & .np < (.i * 0.5)) {
                      mscale <- min(.s)
                      c(.s, rep(mscale / 2, floor(1 / mscale)))
                    } else {
                      .s
                    }
                  }
    )$image,
    path <- withr::local_tempfile(fileext = ".png")
  )

  expect_snapshot_file(path, "circles3.png")

  expect_equal(img1, img2)

  imager::save.image(
    impac(
      function(i) imager::draw_circle(
        imager::imfill(500, 500, val = c(0, 0, 0, 0)),
        250, 250, radius = runif(1, 150, 250),
        color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
      ),
      width = 400, height = 400,
      max_images = 10, bg = "white",
      min_scale = 0.01,
      scaler = if(!.success & .try == 1) c(.s, .s * 0.5) else .s
    )$image,
    path <- withr::local_tempfile(fileext = ".png")
  )

  expect_snapshot_file(path, "circles4.png")


})
