test_that("immosaic produces the same image", {

  set.seed(3717)

  imager::save.image(
    immosaic(
      function(i) imager::draw_circle(
        imager::imfill(500, 500, val = c(0, 0, 0, 0)),
        250, 250, radius = runif(1, 150, 250),
        color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
      ),
      width = 400, height = 400,
      max_images = 10, bg = "white",
    )$image,
    path <- tempfile(fileext = ".png")
  )

  expect_snapshot_file(path, "circles.png")

})
