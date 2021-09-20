convert_to_rgba <- function(img) {

  if(dim(img)[4] == 1) {
    img <- imager::add.color(img, simple = FALSE)
  }

  if(dim(img)[4] == 3) {
    img2 <- imager::imfill(imager::width(img), imager::height(img), val = c(1, 1, 1, 1))
    img2[ , , , 1:3] <- img
    img <- img2
  }

  img
}
