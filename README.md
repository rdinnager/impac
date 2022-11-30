
<!-- README.md is generated from README.Rmd. Please edit that file -->

# impac

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/impac/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/impac/actions)
<!-- badges: end -->

The goal of `{impac}` is to create packed image mosaics. The main
function `impac`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast\!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/impac")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(impac)
library(Rvcg)
library(rgl)
library(rphylopic)
```

Next we create an R function to generate an image. In this case, we use
the package `rgl` to plot a simple 3d shape, chosen randomly from a set
of possibilities:

``` r

generate_platonic <- function(i, swidth = 200, sheight = 200, cols = rainbow(100)) {
  
  shape <- sample(c("sphere",
                    "spherical_cap",
                    "tetrahedron",
                    "dodecahedron",
                    "octahedron",
                    "icosahedron",
                    "hexahedron",
                    "cube",
                    "cone"),
                  1)
  
  mesh <- switch (shape,
    sphere = Rvcg::vcgSphere(),
    spherical_cap = Rvcg::vcgSphericalCap(),
    tetrahedron = Rvcg::vcgTetrahedron(),
    dodecahedron = Rvcg::vcgDodecahedron(),
    octahedron = Rvcg::vcgOctahedron(),
    icosahedron = Rvcg::vcgIcosahedron(),
    hexahedron = Rvcg::vcgHexahedron(),
    cube = Rvcg::vcgBox(),
    cone = Rvcg::vcgCone(2, 0, 6)
  )
  
  scales <- c(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4)
  mesh <- rgl::scale3d(mesh, 
                       sample(scales, 1),
                       sample(scales, 1),
                       sample(scales, 1))
  
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 0, 1)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 1, 0)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 1, 0, 0)
  
  rgl::shade3d(mesh, col = sample(cols, 1),
               specular = "grey")
  
  png_file <- tempfile(fileext = ".png")
  rgl::snapshot3d(filename = png_file, width = swidth, height = sheight,
                  webshot = FALSE)
  rgl::close3d()
  
  im2 <- imager::load.image(png_file)
  im <- imager::imfill(swidth, sheight, val = c(0, 0, 0, 1))
  im[ , , , 1:3] <- im2 
  im[imager::R(im) == 1 & imager::G(im) == 1 & imager::B(im) == 1] <- 0
  
  im  
 
}
```

Now we feed our function to the `impac()` function, which packs the
generated images onto a canvas:

``` r
shapes <- impac(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images\! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::image_list(1, 10000)
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::image_data(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp$uid, c(2, 1, 3))
  dims <- dim(rot)
  im <- imager::as.cimg(as.vector(rot), dim = c(dims[1], dims[2], 1, dims[3]))
  max_dim <- which.max(dims[1:2])
  other_dim <- (max_size / dims[max_dim]) * dims[1:2][-max_dim]
  new_size <- c(0, 0)
  new_size[max_dim] <- max_size
  new_size[-max_dim] <- other_dim
  im <- imager::resize(im, new_size[1], new_size[2], interpolation_type = 6)
  im <- imager::imchange(im, ~ . < 0, ~ 0)
  im <- imager::imchange(im, ~ . > 1, ~ 1)
  ## this adds custom metadata
  list(im, uuid = uuid)
}
```

Now we run `impac` on our phylopic generating function:

``` r
phylopics <- impac(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(2); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Mali’o Kodis, photograph by Jim Vargo, Jake Warner, Yan Wong, Andy
Wilson, Dmitry Bogdanov (vectorized by T. Michael Keesey), Matt Crook,
Zimices, Ferran Sayol, Scott Hartman, Margot Michaud, Andrew A. Farke,
FunkMonk, Abraão Leite, Tasman Dixon, Crystal Maier, Roger Witter,
vectorized by Zimices, NASA, Mo Hassan, Matt Martyniuk, Mike Hanson,
Mathieu Pélissié, Chris huh, Yan Wong (vectorization) from 1873
illustration, M Kolmann, Luis Cunha, Scott D. Sampson, Mark A. Loewen,
Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith,
Alan L. Titus, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Nobu Tamura (vectorized by T. Michael Keesey), Berivan Temiz,
Ville-Veikko Sinkkonen, Steven Traver, Jonathan Wells, Darren Naish
(vectorize by T. Michael Keesey), Maija Karala, Markus A. Grohme, Dmitry
Bogdanov, U.S. Fish and Wildlife Service (illustration) and Timothy J.
Bartley (silhouette), Meliponicultor Itaymbere, Jagged Fang Designs, T.
Michael Keesey, Gareth Monger, Birgit Lang, Zimices, based in Mauricio
Antón skeletal, Michael B. H. (vectorized by T. Michael Keesey), Lily
Hughes, Tony Ayling, T. Tischler, Mihai Dragos (vectorized by T. Michael
Keesey), Michael Day, Jaime Headden, modified by T. Michael Keesey,
Sarah Werning, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Riccardo Percudani, Christoph
Schomburg, Skye M, Milton Tan, Michelle Site, Douglas Brown (modified by
T. Michael Keesey), Matt Celeskey, Cagri Cevrim, Gabriela Palomo-Munoz,
Erika Schumacher, Joanna Wolfe, Ieuan Jones, Rebecca Groom, Mykle Hoban,
Harold N Eyster, T. Michael Keesey (after Ponomarenko), Matt Dempsey,
Caleb M. Brown, Dann Pigdon, Felix Vaux, Mathew Callaghan, Tracy A.
Heath, Almandine (vectorized by T. Michael Keesey), Smokeybjb
(vectorized by T. Michael Keesey), Scott Reid, Original drawing by
Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Chloé Schmidt,
Mathew Wedel, Nick Schooler, Anthony Caravaggi, Kamil S. Jaron,
Christine Axon, Lukas Panzarin, Juan Carlos Jerí, L. Shyamal, Caio
Bernardes, vectorized by Zimices, Carlos Cano-Barbacil, Pedro de
Siracusa, Noah Schlottman, photo by Adam G. Clause, Inessa Voet, Jim
Bendon (photography) and T. Michael Keesey (vectorization), Beth Reinke,
Julio Garza, Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B.
Chaves), Rene Martin, Collin Gross, Tarique Sani (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Dean Schnabel,
Mali’o Kodis, image from the Smithsonian Institution, H. F. O. March
(modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel),
Ville Koistinen (vectorized by T. Michael Keesey), Ignacio Contreras,
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Melissa Ingala, Noah Schlottman, photo from Casey Dunn, L.M.
Davalos, Benchill, Pollyanna von Knorring and T. Michael Keesey,
Mathilde Cordellier, Darius Nau, Cristopher Silva, Madeleine Price Ball,
Martin R. Smith, Luc Viatour (source photo) and Andreas Plank, .
Original drawing by M. Antón, published in Montoya and Morales 1984.
Vectorized by O. Sanisidro, Sharon Wegner-Larsen, Falconaumanni and T.
Michael Keesey, Alexander Schmidt-Lebuhn, Kai R. Caspar, Stanton F.
Fink, vectorized by Zimices, Scarlet23 (vectorized by T. Michael
Keesey), Conty (vectorized by T. Michael Keesey), Melissa Broussard,
Pete Buchholz, Matt Martyniuk (vectorized by T. Michael Keesey),
Fernando Campos De Domenico, Nobu Tamura, vectorized by Zimices, Lani
Mohan, Lukasiniho, Henry Lydecker, Ernst Haeckel (vectorized by T.
Michael Keesey), Xavier Giroux-Bougard, Benjamint444, Jaime Headden,
Scott Hartman (modified by T. Michael Keesey), Saguaro Pictures (source
photo) and T. Michael Keesey, Yan Wong from drawing in The Century
Dictionary (1911), SauropodomorphMonarch, Dmitry Bogdanov (modified by
T. Michael Keesey), TaraTaylorDesign, Cyril Matthey-Doret, adapted from
Bernard Chaubet, Michael Scroggie, Emily Willoughby, Mette Aumala,
Smokeybjb, Ingo Braasch, Alexandre Vong, M Hutchinson, Shyamal, Neil
Kelley, Martin Kevil, Jiekun He, Sarah Alewijnse, John Conway, Maxime
Dahirel, Renato Santos, Roberto Díaz Sibaja, T. Michael Keesey (after
Heinrich Harder), Michael P. Taylor, Zsoldos Márton (vectorized by T.
Michael Keesey), Armin Reindl, Darren Naish (vectorized by T. Michael
Keesey), Stanton F. Fink (vectorized by T. Michael Keesey), Sherman F.
Denton via rawpixel.com (illustration) and Timothy J. Bartley
(silhouette), Steven Blackwood, Alan Manson (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Original drawing by Nobu
Tamura, vectorized by Roberto Díaz Sibaja, Johan Lindgren, Michael W.
Caldwell, Takuya Konishi, Luis M. Chiappe, Tyler McCraney, Cristian
Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Lee Harding (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Cesar Julian, Noah
Schlottman, photo by Antonio Guillén, Ghedoghedo (vectorized by T.
Michael Keesey), C. Camilo Julián-Caballero, Iain Reid, Duane
Raver/USFWS, Chuanixn Yu, Nicholas J. Czaplewski, vectorized by Zimices,
Blanco et al., 2014, vectorized by Zimices, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Mali’o Kodis, photograph by P. Funch and R.M. Kristensen, Noah
Schlottman, Kenneth Lacovara (vectorized by T. Michael Keesey), Jaime
Headden (vectorized by T. Michael Keesey), Mattia Menchetti / Yan Wong,
T. Michael Keesey (after Walker & al.), David Orr

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                       |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     939.80962 |    525.462532 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                        |
|   2 |     388.63224 |    446.523738 | Jake Warner                                                                                                                                                  |
|   3 |     318.66940 |     83.453734 | Yan Wong                                                                                                                                                     |
|   4 |     108.14116 |    662.021187 | Andy Wilson                                                                                                                                                  |
|   5 |     706.33258 |     57.818118 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|   6 |     735.78261 |    535.766701 | Matt Crook                                                                                                                                                   |
|   7 |     811.86663 |    665.208307 | Zimices                                                                                                                                                      |
|   8 |     238.90327 |    579.490947 | Ferran Sayol                                                                                                                                                 |
|   9 |     448.16531 |    591.053864 | Scott Hartman                                                                                                                                                |
|  10 |      64.46181 |    107.761506 | Margot Michaud                                                                                                                                               |
|  11 |     773.07136 |    147.190506 | Andrew A. Farke                                                                                                                                              |
|  12 |     190.28029 |    741.805976 | FunkMonk                                                                                                                                                     |
|  13 |     960.03916 |    223.697410 | Matt Crook                                                                                                                                                   |
|  14 |     554.82738 |    655.712639 | Abraão Leite                                                                                                                                                 |
|  15 |      87.25011 |    275.871185 | Tasman Dixon                                                                                                                                                 |
|  16 |     958.15418 |    737.971463 | Tasman Dixon                                                                                                                                                 |
|  17 |     562.41123 |    207.878896 | Crystal Maier                                                                                                                                                |
|  18 |     293.20685 |    306.745645 | Roger Witter, vectorized by Zimices                                                                                                                          |
|  19 |     718.26341 |    728.233529 | Matt Crook                                                                                                                                                   |
|  20 |     607.49218 |    469.468011 | NASA                                                                                                                                                         |
|  21 |      91.78620 |    371.254679 | Mo Hassan                                                                                                                                                    |
|  22 |     681.94167 |    223.784622 | Matt Martyniuk                                                                                                                                               |
|  23 |     955.89119 |    332.416985 | Mike Hanson                                                                                                                                                  |
|  24 |     263.66377 |    419.923610 | Mathieu Pélissié                                                                                                                                             |
|  25 |     568.52473 |    744.857180 | Chris huh                                                                                                                                                    |
|  26 |      47.77436 |    510.313962 | Yan Wong (vectorization) from 1873 illustration                                                                                                              |
|  27 |     418.36509 |    298.226411 | Zimices                                                                                                                                                      |
|  28 |     411.22822 |    635.046711 | FunkMonk                                                                                                                                                     |
|  29 |     491.27501 |    565.379227 | M Kolmann                                                                                                                                                    |
|  30 |     523.94243 |    465.674587 | Luis Cunha                                                                                                                                                   |
|  31 |     160.13518 |    213.283202 | Tasman Dixon                                                                                                                                                 |
|  32 |     738.04197 |    317.185201 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                     |
|  33 |     611.70331 |    108.235278 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                         |
|  34 |     424.47034 |    731.512933 | Crystal Maier                                                                                                                                                |
|  35 |     463.38793 |    201.575973 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
|  36 |     865.02548 |    377.474092 | Berivan Temiz                                                                                                                                                |
|  37 |     431.95108 |    370.350052 | Ville-Veikko Sinkkonen                                                                                                                                       |
|  38 |     957.76851 |     75.232899 | Steven Traver                                                                                                                                                |
|  39 |     305.87587 |    189.360099 | Jonathan Wells                                                                                                                                               |
|  40 |     170.53366 |     44.202082 | Tasman Dixon                                                                                                                                                 |
|  41 |     517.26461 |    307.576216 | NA                                                                                                                                                           |
|  42 |     895.53710 |    623.035323 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                |
|  43 |     820.18515 |    268.321266 | Maija Karala                                                                                                                                                 |
|  44 |     774.41191 |    414.005777 | Scott Hartman                                                                                                                                                |
|  45 |     835.52836 |    776.217583 | Markus A. Grohme                                                                                                                                             |
|  46 |     207.99662 |    126.058758 | Dmitry Bogdanov                                                                                                                                              |
|  47 |     859.81253 |    107.509570 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                            |
|  48 |     611.50015 |    650.929128 | FunkMonk                                                                                                                                                     |
|  49 |     487.04598 |    108.589503 | Meliponicultor Itaymbere                                                                                                                                     |
|  50 |      71.06875 |    156.651583 | Jagged Fang Designs                                                                                                                                          |
|  51 |     378.66955 |    544.254795 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
|  52 |      93.38400 |    467.655122 | NA                                                                                                                                                           |
|  53 |     609.74219 |    333.997154 | Andy Wilson                                                                                                                                                  |
|  54 |     826.13908 |    200.060719 | T. Michael Keesey                                                                                                                                            |
|  55 |      92.13453 |    582.524874 | Gareth Monger                                                                                                                                                |
|  56 |     320.80765 |    686.803706 | Birgit Lang                                                                                                                                                  |
|  57 |     483.13899 |    627.134064 | Jagged Fang Designs                                                                                                                                          |
|  58 |     886.21423 |    452.988358 | Zimices, based in Mauricio Antón skeletal                                                                                                                    |
|  59 |     317.21892 |    505.538555 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                              |
|  60 |     614.66760 |    293.646870 | Lily Hughes                                                                                                                                                  |
|  61 |     423.74374 |     27.478206 | Chris huh                                                                                                                                                    |
|  62 |     545.66768 |    687.300705 | Scott Hartman                                                                                                                                                |
|  63 |     687.53574 |    123.893142 | Yan Wong                                                                                                                                                     |
|  64 |     939.59898 |    151.999936 | Markus A. Grohme                                                                                                                                             |
|  65 |     739.48067 |    382.862424 | Tony Ayling                                                                                                                                                  |
|  66 |     194.83302 |    422.738028 | T. Tischler                                                                                                                                                  |
|  67 |     258.85292 |    693.988730 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                               |
|  68 |     978.71296 |    609.862418 | Michael Day                                                                                                                                                  |
|  69 |     834.06837 |    727.237132 | Steven Traver                                                                                                                                                |
|  70 |     388.38853 |    410.271042 | Jaime Headden, modified by T. Michael Keesey                                                                                                                 |
|  71 |      79.04597 |     26.888842 | Sarah Werning                                                                                                                                                |
|  72 |    1006.43557 |    352.560739 | NA                                                                                                                                                           |
|  73 |     281.78437 |    228.343321 | Chris huh                                                                                                                                                    |
|  74 |     914.71446 |    172.580412 | Markus A. Grohme                                                                                                                                             |
|  75 |     870.16090 |    308.595756 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                     |
|  76 |     987.46797 |     91.068616 | Chris huh                                                                                                                                                    |
|  77 |     210.03789 |    308.040281 | NA                                                                                                                                                           |
|  78 |     672.33521 |    425.963325 | Andy Wilson                                                                                                                                                  |
|  79 |      71.81429 |     71.845489 | NA                                                                                                                                                           |
|  80 |     941.78153 |    653.944338 | Riccardo Percudani                                                                                                                                           |
|  81 |     141.09908 |    461.131440 | Christoph Schomburg                                                                                                                                          |
|  82 |     351.30345 |    754.663152 | Skye M                                                                                                                                                       |
|  83 |     745.12764 |     17.318837 | Milton Tan                                                                                                                                                   |
|  84 |      57.13594 |    229.725978 | NA                                                                                                                                                           |
|  85 |     399.74632 |    235.408750 | Michelle Site                                                                                                                                                |
|  86 |     567.99026 |     79.373183 | Tasman Dixon                                                                                                                                                 |
|  87 |     930.66846 |    706.425591 | Zimices                                                                                                                                                      |
|  88 |      49.06538 |    323.674361 | Margot Michaud                                                                                                                                               |
|  89 |     202.11676 |    351.761887 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                |
|  90 |     462.27736 |    455.574906 | Matt Crook                                                                                                                                                   |
|  91 |     813.16692 |    312.971072 | NA                                                                                                                                                           |
|  92 |     821.34751 |    617.437539 | Matt Celeskey                                                                                                                                                |
|  93 |     183.73887 |    373.527745 | Ferran Sayol                                                                                                                                                 |
|  94 |      17.85253 |    386.840448 | Cagri Cevrim                                                                                                                                                 |
|  95 |     152.22441 |    310.928108 | Gabriela Palomo-Munoz                                                                                                                                        |
|  96 |     670.99311 |    343.870591 | Erika Schumacher                                                                                                                                             |
|  97 |     729.87527 |    187.596930 | T. Michael Keesey                                                                                                                                            |
|  98 |     443.66983 |     82.988893 | Ferran Sayol                                                                                                                                                 |
|  99 |     295.57428 |    549.045447 | Joanna Wolfe                                                                                                                                                 |
| 100 |     185.25189 |    259.624458 | Ieuan Jones                                                                                                                                                  |
| 101 |      54.08725 |    438.694517 | Rebecca Groom                                                                                                                                                |
| 102 |     561.92120 |    451.534139 | Mykle Hoban                                                                                                                                                  |
| 103 |     478.05033 |    540.397298 | Harold N Eyster                                                                                                                                              |
| 104 |     642.46169 |    234.834272 | Ferran Sayol                                                                                                                                                 |
| 105 |     139.11301 |    156.262734 | Chris huh                                                                                                                                                    |
| 106 |     268.40834 |     23.789597 | Zimices                                                                                                                                                      |
| 107 |      22.99957 |    660.333030 | Zimices                                                                                                                                                      |
| 108 |     900.90368 |    215.016864 | T. Michael Keesey (after Ponomarenko)                                                                                                                        |
| 109 |      55.12355 |    415.726996 | Margot Michaud                                                                                                                                               |
| 110 |     673.39837 |     94.742860 | Matt Dempsey                                                                                                                                                 |
| 111 |     216.70585 |    186.146314 | Caleb M. Brown                                                                                                                                               |
| 112 |     321.30514 |    791.178643 | Zimices                                                                                                                                                      |
| 113 |     140.08274 |    587.718839 | NA                                                                                                                                                           |
| 114 |     991.55225 |    792.557742 | Dann Pigdon                                                                                                                                                  |
| 115 |     973.16251 |    451.715573 | Gareth Monger                                                                                                                                                |
| 116 |     853.33487 |    151.894648 | Felix Vaux                                                                                                                                                   |
| 117 |     610.05559 |    240.109896 | Andy Wilson                                                                                                                                                  |
| 118 |     862.56755 |    520.460274 | Gabriela Palomo-Munoz                                                                                                                                        |
| 119 |     607.26192 |    157.818652 | Gabriela Palomo-Munoz                                                                                                                                        |
| 120 |     277.93797 |     38.714841 | Scott Hartman                                                                                                                                                |
| 121 |     385.19877 |    163.976359 | Mathew Callaghan                                                                                                                                             |
| 122 |     895.91313 |    332.995059 | Tracy A. Heath                                                                                                                                               |
| 123 |     497.04173 |    740.278229 | Matt Crook                                                                                                                                                   |
| 124 |     244.31169 |    514.912942 | Almandine (vectorized by T. Michael Keesey)                                                                                                                  |
| 125 |     201.54855 |    464.298402 | Christoph Schomburg                                                                                                                                          |
| 126 |     868.12895 |    544.612127 | Ferran Sayol                                                                                                                                                 |
| 127 |     775.35760 |    109.648086 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                  |
| 128 |      79.90200 |    736.171376 | Tasman Dixon                                                                                                                                                 |
| 129 |    1000.80533 |     27.946519 | Scott Reid                                                                                                                                                   |
| 130 |     488.85734 |    226.321730 | Margot Michaud                                                                                                                                               |
| 131 |      55.12651 |    193.586951 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                       |
| 132 |     623.59650 |    624.571437 | Chloé Schmidt                                                                                                                                                |
| 133 |     805.73409 |    162.654753 | NA                                                                                                                                                           |
| 134 |     340.07250 |    267.126331 | Mathew Wedel                                                                                                                                                 |
| 135 |     216.50476 |    480.430454 | Steven Traver                                                                                                                                                |
| 136 |     934.08915 |    585.779466 | T. Michael Keesey                                                                                                                                            |
| 137 |     622.40886 |    710.988548 | Nick Schooler                                                                                                                                                |
| 138 |     563.41202 |    604.358865 | Anthony Caravaggi                                                                                                                                            |
| 139 |      40.10182 |    770.353681 | Matt Crook                                                                                                                                                   |
| 140 |     908.10071 |    771.988758 | Kamil S. Jaron                                                                                                                                               |
| 141 |     728.39070 |    359.250545 | Christine Axon                                                                                                                                               |
| 142 |     574.96716 |    540.481113 | Chloé Schmidt                                                                                                                                                |
| 143 |     811.83649 |     78.742740 | Maija Karala                                                                                                                                                 |
| 144 |     254.42405 |    441.749384 | Chris huh                                                                                                                                                    |
| 145 |     893.28784 |    728.762366 | Lukas Panzarin                                                                                                                                               |
| 146 |     240.04206 |    329.382344 | Juan Carlos Jerí                                                                                                                                             |
| 147 |     934.27885 |    189.544786 | Steven Traver                                                                                                                                                |
| 148 |    1001.41032 |    469.670725 | L. Shyamal                                                                                                                                                   |
| 149 |     729.22263 |    636.481480 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 150 |     326.30528 |    131.549417 | Matt Dempsey                                                                                                                                                 |
| 151 |     693.85685 |    643.643001 | Gabriela Palomo-Munoz                                                                                                                                        |
| 152 |     242.71311 |    782.594257 | Margot Michaud                                                                                                                                               |
| 153 |     604.33041 |     82.224469 | Gareth Monger                                                                                                                                                |
| 154 |     582.09890 |    149.494810 | Caio Bernardes, vectorized by Zimices                                                                                                                        |
| 155 |     810.19263 |    342.559929 | Carlos Cano-Barbacil                                                                                                                                         |
| 156 |     436.08571 |    115.619118 | NA                                                                                                                                                           |
| 157 |     566.87661 |      9.372940 | Yan Wong                                                                                                                                                     |
| 158 |     651.54261 |    380.162482 | Pedro de Siracusa                                                                                                                                            |
| 159 |     554.30810 |    343.187105 | Birgit Lang                                                                                                                                                  |
| 160 |     630.63633 |    589.737086 | Matt Crook                                                                                                                                                   |
| 161 |     612.45467 |    770.667878 | Gabriela Palomo-Munoz                                                                                                                                        |
| 162 |     235.05911 |    429.916680 | NA                                                                                                                                                           |
| 163 |      99.83030 |    228.673255 | Noah Schlottman, photo by Adam G. Clause                                                                                                                     |
| 164 |     973.71438 |    115.464845 | Markus A. Grohme                                                                                                                                             |
| 165 |     502.96062 |    173.897790 | Markus A. Grohme                                                                                                                                             |
| 166 |     825.53468 |     90.675769 | Matt Crook                                                                                                                                                   |
| 167 |     794.63943 |    335.770527 | Inessa Voet                                                                                                                                                  |
| 168 |     356.85901 |    365.019362 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 169 |     753.78431 |    278.638255 | Steven Traver                                                                                                                                                |
| 170 |      95.76150 |    779.103830 | Scott Hartman                                                                                                                                                |
| 171 |     237.98848 |    216.699728 | Mathew Wedel                                                                                                                                                 |
| 172 |     658.99968 |    359.453452 | Gareth Monger                                                                                                                                                |
| 173 |     952.90166 |    791.869466 | Gabriela Palomo-Munoz                                                                                                                                        |
| 174 |     376.95217 |    200.763725 | Beth Reinke                                                                                                                                                  |
| 175 |     494.67776 |    250.810740 | Julio Garza                                                                                                                                                  |
| 176 |     121.67689 |    535.117034 | Mo Hassan                                                                                                                                                    |
| 177 |     404.38887 |    121.393466 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                          |
| 178 |      28.41420 |    701.827548 | Rene Martin                                                                                                                                                  |
| 179 |      32.87824 |    715.561624 | Collin Gross                                                                                                                                                 |
| 180 |     343.19358 |      4.851054 | Scott Hartman                                                                                                                                                |
| 181 |     488.87085 |    608.434691 | Margot Michaud                                                                                                                                               |
| 182 |     523.85788 |    590.450218 | Ieuan Jones                                                                                                                                                  |
| 183 |     512.94496 |    387.607392 | NA                                                                                                                                                           |
| 184 |     134.04173 |     27.445968 | Jagged Fang Designs                                                                                                                                          |
| 185 |     249.48034 |    546.077519 | Ferran Sayol                                                                                                                                                 |
| 186 |      35.47317 |     77.243374 | Gabriela Palomo-Munoz                                                                                                                                        |
| 187 |      18.03309 |    453.211720 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 188 |     983.31464 |    273.189933 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 189 |     940.83793 |    410.136453 | Sarah Werning                                                                                                                                                |
| 190 |     104.48844 |    753.046330 | Jagged Fang Designs                                                                                                                                          |
| 191 |     468.44943 |    782.754869 | Dean Schnabel                                                                                                                                                |
| 192 |      16.03019 |    568.836549 | Zimices                                                                                                                                                      |
| 193 |     744.40514 |    262.476274 | Carlos Cano-Barbacil                                                                                                                                         |
| 194 |     981.46706 |    629.283586 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                         |
| 195 |     110.75062 |    605.445113 | NA                                                                                                                                                           |
| 196 |     568.19096 |    579.360484 | Erika Schumacher                                                                                                                                             |
| 197 |     302.79525 |    781.518769 | Mathieu Pélissié                                                                                                                                             |
| 198 |     873.14980 |    645.512334 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                         |
| 199 |     645.90522 |    755.933918 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                            |
| 200 |     601.97272 |    599.564053 | NA                                                                                                                                                           |
| 201 |     188.71874 |    684.668860 | Ignacio Contreras                                                                                                                                            |
| 202 |       9.24257 |    281.746617 | Felix Vaux                                                                                                                                                   |
| 203 |     423.87081 |    268.569252 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                     |
| 204 |     293.11330 |    586.024270 | Melissa Ingala                                                                                                                                               |
| 205 |     373.00089 |    643.891967 | Jagged Fang Designs                                                                                                                                          |
| 206 |     652.46214 |    706.569435 | Noah Schlottman, photo from Casey Dunn                                                                                                                       |
| 207 |     815.57779 |    702.044743 | L.M. Davalos                                                                                                                                                 |
| 208 |     786.09699 |    432.437162 | Benchill                                                                                                                                                     |
| 209 |     368.16040 |    235.224335 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                               |
| 210 |     576.02339 |    485.403160 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                 |
| 211 |     799.12472 |    357.195021 | Harold N Eyster                                                                                                                                              |
| 212 |     346.22038 |    329.766704 | Mathilde Cordellier                                                                                                                                          |
| 213 |     690.10927 |    362.822076 | Markus A. Grohme                                                                                                                                             |
| 214 |      27.84401 |    738.673785 | Scott Hartman                                                                                                                                                |
| 215 |     954.47369 |     27.146071 | Darius Nau                                                                                                                                                   |
| 216 |     689.01618 |    172.253839 | Cristopher Silva                                                                                                                                             |
| 217 |      29.65514 |    588.907087 | Michelle Site                                                                                                                                                |
| 218 |     687.22190 |     11.261915 | Zimices                                                                                                                                                      |
| 219 |     461.53264 |    496.133570 | Margot Michaud                                                                                                                                               |
| 220 |     550.07546 |    309.792584 | Madeleine Price Ball                                                                                                                                         |
| 221 |     163.80424 |     92.782319 | T. Michael Keesey                                                                                                                                            |
| 222 |     789.38230 |    758.638836 | T. Michael Keesey                                                                                                                                            |
| 223 |     145.19121 |    144.197212 | Martin R. Smith                                                                                                                                              |
| 224 |      96.08593 |    323.415437 | NA                                                                                                                                                           |
| 225 |     130.94386 |    574.879731 | Zimices                                                                                                                                                      |
| 226 |     508.16968 |    189.654059 | Margot Michaud                                                                                                                                               |
| 227 |      15.53247 |    614.272497 | Matt Crook                                                                                                                                                   |
| 228 |     813.94960 |    433.428087 | NA                                                                                                                                                           |
| 229 |     860.30145 |    747.105412 | Luc Viatour (source photo) and Andreas Plank                                                                                                                 |
| 230 |     981.42730 |    400.515021 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                            |
| 231 |     505.17692 |    517.561957 | Sharon Wegner-Larsen                                                                                                                                         |
| 232 |     555.37724 |    418.314108 | Falconaumanni and T. Michael Keesey                                                                                                                          |
| 233 |     527.59054 |    610.943264 | Margot Michaud                                                                                                                                               |
| 234 |     357.68290 |    723.388862 | Sharon Wegner-Larsen                                                                                                                                         |
| 235 |     380.41387 |    142.339301 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 236 |     953.37014 |    682.026282 | NA                                                                                                                                                           |
| 237 |     931.97974 |    287.985815 | Scott Hartman                                                                                                                                                |
| 238 |     123.17328 |    496.919293 | Kai R. Caspar                                                                                                                                                |
| 239 |     571.65060 |    691.428630 | Mike Hanson                                                                                                                                                  |
| 240 |     823.37043 |     17.843125 | Matt Crook                                                                                                                                                   |
| 241 |     691.11752 |    396.001152 | Steven Traver                                                                                                                                                |
| 242 |      18.39692 |     52.304166 | Ignacio Contreras                                                                                                                                            |
| 243 |     324.75597 |     31.112525 | Stanton F. Fink, vectorized by Zimices                                                                                                                       |
| 244 |     708.11539 |     29.424264 | Tracy A. Heath                                                                                                                                               |
| 245 |     182.90065 |    645.575843 | Gareth Monger                                                                                                                                                |
| 246 |     347.97907 |    254.690452 | Gareth Monger                                                                                                                                                |
| 247 |     509.68288 |    779.802378 | Dmitry Bogdanov                                                                                                                                              |
| 248 |    1006.19939 |    435.999217 | NA                                                                                                                                                           |
| 249 |      77.35481 |    550.679827 | Jagged Fang Designs                                                                                                                                          |
| 250 |     787.43715 |    231.577199 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                  |
| 251 |     512.88718 |    640.586490 | Matt Martyniuk                                                                                                                                               |
| 252 |     212.37950 |    791.305028 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 253 |     414.44055 |    468.130098 | Chris huh                                                                                                                                                    |
| 254 |     228.56900 |     50.716003 | Matt Crook                                                                                                                                                   |
| 255 |     175.35895 |    174.848602 | Conty (vectorized by T. Michael Keesey)                                                                                                                      |
| 256 |     455.88225 |    105.923439 | Jagged Fang Designs                                                                                                                                          |
| 257 |     891.74041 |    758.483159 | Gareth Monger                                                                                                                                                |
| 258 |     499.11083 |    706.101333 | Melissa Broussard                                                                                                                                            |
| 259 |     928.61951 |    760.558800 | Andrew A. Farke                                                                                                                                              |
| 260 |     463.41704 |    329.256848 | Scott Hartman                                                                                                                                                |
| 261 |      35.98444 |    189.169181 | Matt Crook                                                                                                                                                   |
| 262 |     576.65042 |    514.569881 | Pete Buchholz                                                                                                                                                |
| 263 |     533.23325 |    132.261685 | Zimices                                                                                                                                                      |
| 264 |      87.21497 |    630.740129 | Matt Crook                                                                                                                                                   |
| 265 |     733.19736 |    244.831285 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                             |
| 266 |     571.42235 |    367.640920 | T. Michael Keesey                                                                                                                                            |
| 267 |     992.71955 |    677.343220 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 268 |     218.95716 |    229.891344 | Gareth Monger                                                                                                                                                |
| 269 |     205.27438 |    214.703744 | Tasman Dixon                                                                                                                                                 |
| 270 |     861.76187 |    245.871789 | NA                                                                                                                                                           |
| 271 |    1002.40585 |     10.452302 | Zimices                                                                                                                                                      |
| 272 |     491.01432 |    652.509244 | Gareth Monger                                                                                                                                                |
| 273 |     643.90809 |    625.525786 | Birgit Lang                                                                                                                                                  |
| 274 |     368.19702 |    624.483056 | T. Michael Keesey                                                                                                                                            |
| 275 |     750.59279 |    670.384092 | Jagged Fang Designs                                                                                                                                          |
| 276 |     251.63077 |    359.738141 | Matt Crook                                                                                                                                                   |
| 277 |      12.35993 |    541.069858 | Gareth Monger                                                                                                                                                |
| 278 |     270.75800 |    716.788175 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 279 |     359.06807 |     21.951572 | Gabriela Palomo-Munoz                                                                                                                                        |
| 280 |     226.24331 |    159.327659 | Fernando Campos De Domenico                                                                                                                                  |
| 281 |     495.19437 |    215.161897 | Collin Gross                                                                                                                                                 |
| 282 |     857.29272 |    500.738305 | Markus A. Grohme                                                                                                                                             |
| 283 |     277.35726 |    149.373119 | Gareth Monger                                                                                                                                                |
| 284 |     463.17498 |    555.916020 | Jagged Fang Designs                                                                                                                                          |
| 285 |     901.39977 |     57.919071 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                       |
| 286 |     283.77424 |    669.101042 | Steven Traver                                                                                                                                                |
| 287 |     826.79016 |    236.077748 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 288 |     427.89831 |    791.314165 | Steven Traver                                                                                                                                                |
| 289 |     288.16629 |    759.602496 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
| 290 |     999.85117 |    538.378093 | Lani Mohan                                                                                                                                                   |
| 291 |     592.76853 |    715.295205 | Lukasiniho                                                                                                                                                   |
| 292 |     738.58991 |    117.030678 | Henry Lydecker                                                                                                                                               |
| 293 |     803.39171 |    454.151065 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 294 |     857.54515 |     91.140212 | Jagged Fang Designs                                                                                                                                          |
| 295 |     557.76228 |    784.917008 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                              |
| 296 |     548.16303 |    265.638750 | Xavier Giroux-Bougard                                                                                                                                        |
| 297 |     465.60933 |    695.618604 | Beth Reinke                                                                                                                                                  |
| 298 |     385.25444 |     10.351004 | Gabriela Palomo-Munoz                                                                                                                                        |
| 299 |     131.09790 |    245.233418 | Ignacio Contreras                                                                                                                                            |
| 300 |     314.20638 |    729.427329 | NA                                                                                                                                                           |
| 301 |     527.44820 |     89.119831 | Felix Vaux                                                                                                                                                   |
| 302 |     336.64099 |     17.181853 | Carlos Cano-Barbacil                                                                                                                                         |
| 303 |     905.07977 |    588.200409 | Benjamint444                                                                                                                                                 |
| 304 |     751.46749 |    223.825730 | Scott Hartman                                                                                                                                                |
| 305 |     141.95914 |     97.477722 | Jaime Headden                                                                                                                                                |
| 306 |     276.50698 |    639.182533 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 307 |      81.66375 |     49.596564 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 308 |     462.77237 |    421.827219 | Steven Traver                                                                                                                                                |
| 309 |     793.76132 |     32.775947 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                |
| 310 |      75.06544 |    133.691139 | Dean Schnabel                                                                                                                                                |
| 311 |     384.78117 |    716.375207 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                        |
| 312 |     609.06110 |    573.709239 | Andy Wilson                                                                                                                                                  |
| 313 |     111.01225 |    133.738463 | Gareth Monger                                                                                                                                                |
| 314 |     378.03990 |    658.271163 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                       |
| 315 |     382.08281 |    265.420993 | NA                                                                                                                                                           |
| 316 |     203.18268 |    174.596021 | Markus A. Grohme                                                                                                                                             |
| 317 |     942.80076 |    379.869106 | Julio Garza                                                                                                                                                  |
| 318 |     395.22643 |    480.747938 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 319 |     133.61938 |    433.554599 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 320 |     707.25711 |    150.324263 | Xavier Giroux-Bougard                                                                                                                                        |
| 321 |     194.68932 |    486.276332 | SauropodomorphMonarch                                                                                                                                        |
| 322 |     643.95292 |    397.724843 | Jagged Fang Designs                                                                                                                                          |
| 323 |     329.77730 |    410.765710 | L. Shyamal                                                                                                                                                   |
| 324 |     722.12198 |    647.188482 | Rebecca Groom                                                                                                                                                |
| 325 |     187.04528 |    701.280417 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                              |
| 326 |     478.35835 |    600.270989 | Markus A. Grohme                                                                                                                                             |
| 327 |      14.83857 |    175.806129 | Matt Crook                                                                                                                                                   |
| 328 |    1008.18214 |     70.958875 | TaraTaylorDesign                                                                                                                                             |
| 329 |     215.23520 |    405.565518 | Scott Hartman                                                                                                                                                |
| 330 |     228.05157 |    383.773518 | T. Michael Keesey                                                                                                                                            |
| 331 |     670.15087 |    628.565993 | Steven Traver                                                                                                                                                |
| 332 |     401.11026 |    329.870741 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                            |
| 333 |     841.77258 |    748.208153 | Michael Scroggie                                                                                                                                             |
| 334 |     888.85875 |     35.259469 | Matt Crook                                                                                                                                                   |
| 335 |     430.05408 |    438.613944 | Emily Willoughby                                                                                                                                             |
| 336 |     553.08441 |    380.080964 | Riccardo Percudani                                                                                                                                           |
| 337 |     885.17756 |    425.160895 | Mette Aumala                                                                                                                                                 |
| 338 |     192.62556 |    712.559658 | Xavier Giroux-Bougard                                                                                                                                        |
| 339 |     520.46303 |     25.566731 | Smokeybjb                                                                                                                                                    |
| 340 |     466.37950 |    271.239141 | NA                                                                                                                                                           |
| 341 |     646.15840 |      4.125597 | T. Tischler                                                                                                                                                  |
| 342 |      15.64112 |    336.630154 | Ingo Braasch                                                                                                                                                 |
| 343 |     882.52124 |    133.189551 | Margot Michaud                                                                                                                                               |
| 344 |     339.65567 |    151.267217 | Christine Axon                                                                                                                                               |
| 345 |     435.76507 |    136.001726 | Erika Schumacher                                                                                                                                             |
| 346 |     159.69297 |    649.898864 | Alexandre Vong                                                                                                                                               |
| 347 |     489.54211 |    301.207260 | Margot Michaud                                                                                                                                               |
| 348 |     238.01786 |     37.461981 | Collin Gross                                                                                                                                                 |
| 349 |     424.55409 |    557.722921 | Margot Michaud                                                                                                                                               |
| 350 |      35.10771 |    425.188871 | Maija Karala                                                                                                                                                 |
| 351 |     978.64066 |    318.053939 | Scott Hartman                                                                                                                                                |
| 352 |     761.87814 |    295.990075 | M Hutchinson                                                                                                                                                 |
| 353 |     556.12026 |    471.822276 | Jagged Fang Designs                                                                                                                                          |
| 354 |     955.86521 |    447.161081 | Gareth Monger                                                                                                                                                |
| 355 |     526.41893 |    726.454625 | Sarah Werning                                                                                                                                                |
| 356 |     322.90108 |    380.279640 | L. Shyamal                                                                                                                                                   |
| 357 |     900.14900 |    314.604944 | Zimices                                                                                                                                                      |
| 358 |     383.20063 |    583.809526 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 359 |     695.85365 |    415.940358 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 360 |     877.39166 |    279.577964 | Dean Schnabel                                                                                                                                                |
| 361 |     244.70944 |    125.342427 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 362 |     908.20119 |     13.910118 | T. Michael Keesey                                                                                                                                            |
| 363 |     487.97345 |     10.602761 | Shyamal                                                                                                                                                      |
| 364 |     660.24651 |    790.466135 | Zimices                                                                                                                                                      |
| 365 |     917.64608 |     38.444932 | Erika Schumacher                                                                                                                                             |
| 366 |      28.39782 |    303.546999 | Neil Kelley                                                                                                                                                  |
| 367 |     767.37277 |    360.186019 | Zimices                                                                                                                                                      |
| 368 |     716.52375 |    280.025753 | Andrew A. Farke                                                                                                                                              |
| 369 |     242.79243 |    764.857980 | Erika Schumacher                                                                                                                                             |
| 370 |     517.92184 |    553.253771 | Martin Kevil                                                                                                                                                 |
| 371 |     349.00918 |    315.972501 | Jiekun He                                                                                                                                                    |
| 372 |     192.55286 |    449.774277 | Ferran Sayol                                                                                                                                                 |
| 373 |     851.62887 |    792.392657 | Chris huh                                                                                                                                                    |
| 374 |     226.16645 |    439.689190 | Sarah Alewijnse                                                                                                                                              |
| 375 |     494.85808 |    261.064817 | Margot Michaud                                                                                                                                               |
| 376 |     394.79202 |    600.957029 | Scott Hartman                                                                                                                                                |
| 377 |     593.29123 |     70.791274 | Margot Michaud                                                                                                                                               |
| 378 |     670.15079 |    158.334901 | NA                                                                                                                                                           |
| 379 |     605.99574 |    267.278815 | Beth Reinke                                                                                                                                                  |
| 380 |      77.30533 |    534.834059 | Gareth Monger                                                                                                                                                |
| 381 |     854.19092 |     73.061950 | John Conway                                                                                                                                                  |
| 382 |     881.57397 |    694.285885 | Chris huh                                                                                                                                                    |
| 383 |     298.91616 |    731.757818 | Maxime Dahirel                                                                                                                                               |
| 384 |     174.66646 |    480.122483 | Gareth Monger                                                                                                                                                |
| 385 |     970.02883 |    344.269450 | NA                                                                                                                                                           |
| 386 |     231.38672 |    711.141452 | Shyamal                                                                                                                                                      |
| 387 |     694.12270 |    790.709491 | Collin Gross                                                                                                                                                 |
| 388 |      51.11053 |    662.678537 | Melissa Broussard                                                                                                                                            |
| 389 |     996.09322 |    112.311725 | Ingo Braasch                                                                                                                                                 |
| 390 |     604.51702 |    698.081982 | Mette Aumala                                                                                                                                                 |
| 391 |     561.33247 |    704.138633 | Chris huh                                                                                                                                                    |
| 392 |     115.74444 |    187.621097 | Smokeybjb                                                                                                                                                    |
| 393 |     418.42915 |     54.059703 | Jagged Fang Designs                                                                                                                                          |
| 394 |      81.41887 |    200.913344 | Renato Santos                                                                                                                                                |
| 395 |     248.69739 |    205.550812 | Margot Michaud                                                                                                                                               |
| 396 |     838.72011 |    576.310087 | Roberto Díaz Sibaja                                                                                                                                          |
| 397 |     889.33180 |    243.092036 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 398 |     846.50912 |    611.707158 | T. Michael Keesey (after Heinrich Harder)                                                                                                                    |
| 399 |     757.13854 |    206.899861 | NA                                                                                                                                                           |
| 400 |     721.74484 |     93.684363 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 401 |     543.17527 |      5.772185 | Jagged Fang Designs                                                                                                                                          |
| 402 |     630.88466 |    262.901488 | Michael P. Taylor                                                                                                                                            |
| 403 |     774.84167 |    776.007886 | Margot Michaud                                                                                                                                               |
| 404 |      81.64831 |    322.002047 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 405 |    1008.77626 |    251.171942 | Matt Crook                                                                                                                                                   |
| 406 |     659.43322 |    314.391993 | T. Michael Keesey                                                                                                                                            |
| 407 |     335.71758 |    481.140576 | NA                                                                                                                                                           |
| 408 |     570.98112 |    764.506432 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                             |
| 409 |     396.37539 |    558.796502 | Noah Schlottman, photo by Adam G. Clause                                                                                                                     |
| 410 |     259.84393 |    658.095821 | NA                                                                                                                                                           |
| 411 |     515.34645 |    575.473849 | Armin Reindl                                                                                                                                                 |
| 412 |     918.98576 |    207.325548 | T. Michael Keesey                                                                                                                                            |
| 413 |     273.86820 |    375.267882 | Steven Traver                                                                                                                                                |
| 414 |      17.50816 |    681.947660 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                               |
| 415 |     850.52665 |     11.408822 | Noah Schlottman, photo from Casey Dunn                                                                                                                       |
| 416 |     848.79702 |    337.356964 | Jagged Fang Designs                                                                                                                                          |
| 417 |     702.85405 |    452.880123 | Chris huh                                                                                                                                                    |
| 418 |      25.26882 |     67.963379 | NA                                                                                                                                                           |
| 419 |     798.80522 |    300.896009 | Jagged Fang Designs                                                                                                                                          |
| 420 |     726.92717 |    425.420300 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                            |
| 421 |     986.19220 |    128.266406 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                        |
| 422 |      10.16598 |    481.742348 | Crystal Maier                                                                                                                                                |
| 423 |     373.35213 |    791.250938 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 424 |      53.53127 |    737.742024 | Steven Blackwood                                                                                                                                             |
| 425 |     536.89875 |    440.836569 | Matt Crook                                                                                                                                                   |
| 426 |     399.02302 |    455.551972 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 427 |     337.12738 |    609.697996 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                           |
| 428 |     837.73539 |    482.296083 | Steven Traver                                                                                                                                                |
| 429 |     303.93399 |     18.731110 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                         |
| 430 |     578.21875 |    555.349066 | Gabriela Palomo-Munoz                                                                                                                                        |
| 431 |      15.37556 |    258.901613 | Tyler McCraney                                                                                                                                               |
| 432 |     747.88744 |    127.144583 | Jagged Fang Designs                                                                                                                                          |
| 433 |     540.15681 |    119.945491 | Margot Michaud                                                                                                                                               |
| 434 |      24.38131 |    631.036526 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                 |
| 435 |     157.05325 |     14.875095 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 436 |     173.10433 |    792.896944 | Christine Axon                                                                                                                                               |
| 437 |     641.11434 |    116.066061 | Ignacio Contreras                                                                                                                                            |
| 438 |     886.93410 |    185.148408 | Jaime Headden                                                                                                                                                |
| 439 |     776.32877 |    689.749662 | Martin R. Smith                                                                                                                                              |
| 440 |     526.60080 |    710.795590 | Andy Wilson                                                                                                                                                  |
| 441 |     529.13137 |    538.079077 | Emily Willoughby                                                                                                                                             |
| 442 |     344.35133 |    429.205340 | Zimices                                                                                                                                                      |
| 443 |     724.51439 |    396.548747 | Riccardo Percudani                                                                                                                                           |
| 444 |     538.09724 |    398.573625 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 445 |    1009.39480 |    137.766558 | Gareth Monger                                                                                                                                                |
| 446 |      15.96313 |    689.341230 | Cesar Julian                                                                                                                                                 |
| 447 |     897.52086 |     89.119139 | Markus A. Grohme                                                                                                                                             |
| 448 |     997.77580 |    246.309542 | Noah Schlottman, photo by Antonio Guillén                                                                                                                    |
| 449 |     941.88798 |    495.778567 | Tasman Dixon                                                                                                                                                 |
| 450 |     724.93242 |      6.655830 | Jagged Fang Designs                                                                                                                                          |
| 451 |     651.56536 |    683.130942 | Mo Hassan                                                                                                                                                    |
| 452 |     500.87904 |     43.495330 | Chloé Schmidt                                                                                                                                                |
| 453 |     345.61023 |    508.103888 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 454 |     826.88953 |    633.578078 | Jagged Fang Designs                                                                                                                                          |
| 455 |     280.28197 |    775.973891 | Zimices                                                                                                                                                      |
| 456 |     166.16760 |    286.563692 | Ignacio Contreras                                                                                                                                            |
| 457 |     561.02542 |    277.731942 | Martin Kevil                                                                                                                                                 |
| 458 |     204.68862 |    239.759929 | C. Camilo Julián-Caballero                                                                                                                                   |
| 459 |     977.65909 |    298.101242 | Iain Reid                                                                                                                                                    |
| 460 |     612.68390 |    208.430573 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 461 |     994.69356 |    782.642092 | Scott Hartman                                                                                                                                                |
| 462 |      25.06119 |    123.940526 | Anthony Caravaggi                                                                                                                                            |
| 463 |     588.06428 |    787.842453 | T. Michael Keesey                                                                                                                                            |
| 464 |     145.39689 |    793.027276 | Markus A. Grohme                                                                                                                                             |
| 465 |     582.78029 |     60.026146 | Duane Raver/USFWS                                                                                                                                            |
| 466 |     529.63846 |    761.381463 | NA                                                                                                                                                           |
| 467 |     817.69550 |    128.381829 | Tasman Dixon                                                                                                                                                 |
| 468 |    1003.54486 |    162.117287 | Markus A. Grohme                                                                                                                                             |
| 469 |     951.57214 |    784.757749 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 470 |     299.10639 |    142.310515 | Maija Karala                                                                                                                                                 |
| 471 |     525.99628 |    468.346778 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 472 |     472.58944 |    670.916190 | Caleb M. Brown                                                                                                                                               |
| 473 |     247.26347 |    521.681155 | Iain Reid                                                                                                                                                    |
| 474 |     971.52637 |      4.779513 | T. Michael Keesey                                                                                                                                            |
| 475 |     896.64280 |    471.892073 | Melissa Ingala                                                                                                                                               |
| 476 |    1007.83715 |    692.836330 | Chris huh                                                                                                                                                    |
| 477 |     688.11810 |    194.843383 | Mike Hanson                                                                                                                                                  |
| 478 |      18.81709 |    237.026319 | Chuanixn Yu                                                                                                                                                  |
| 479 |     462.80729 |     11.038408 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                |
| 480 |     827.72830 |    225.198060 | Jagged Fang Designs                                                                                                                                          |
| 481 |     378.86741 |    247.773398 | Zimices                                                                                                                                                      |
| 482 |     771.80341 |    120.346556 | Shyamal                                                                                                                                                      |
| 483 |     472.51860 |    743.547084 | Martin R. Smith                                                                                                                                              |
| 484 |     881.29863 |    216.823097 | Tasman Dixon                                                                                                                                                 |
| 485 |     402.34980 |    417.365278 | Iain Reid                                                                                                                                                    |
| 486 |    1014.75628 |    597.452028 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 487 |     624.75123 |    174.093017 | Ferran Sayol                                                                                                                                                 |
| 488 |     422.47751 |    455.479675 | Rene Martin                                                                                                                                                  |
| 489 |     955.82566 |     11.954596 | Chris huh                                                                                                                                                    |
| 490 |     984.05326 |     30.363839 | Mike Hanson                                                                                                                                                  |
| 491 |     305.60120 |    595.302168 | Jagged Fang Designs                                                                                                                                          |
| 492 |     479.59755 |    594.638212 | Blanco et al., 2014, vectorized by Zimices                                                                                                                   |
| 493 |     193.16568 |     73.478988 | Gareth Monger                                                                                                                                                |
| 494 |      69.49938 |    561.705419 | Chris huh                                                                                                                                                    |
| 495 |     964.21348 |    103.556101 | Ignacio Contreras                                                                                                                                            |
| 496 |     857.64819 |    408.292898 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 497 |      35.06008 |    410.609175 | Scott Hartman                                                                                                                                                |
| 498 |     112.37889 |    426.759260 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                  |
| 499 |     240.07736 |    475.127991 | Shyamal                                                                                                                                                      |
| 500 |     619.84736 |    364.427067 | Zimices                                                                                                                                                      |
| 501 |     110.50096 |     79.949084 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                     |
| 502 |     330.97525 |     37.420366 | Mette Aumala                                                                                                                                                 |
| 503 |     942.24077 |    394.703868 | Noah Schlottman                                                                                                                                              |
| 504 |     323.81273 |    762.258150 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                           |
| 505 |     928.92798 |    349.854422 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                              |
| 506 |    1001.99202 |    654.577444 | NA                                                                                                                                                           |
| 507 |     529.05170 |    425.700539 | Ingo Braasch                                                                                                                                                 |
| 508 |     479.59401 |    721.474645 | Chris huh                                                                                                                                                    |
| 509 |      23.51345 |    753.594143 | Matt Crook                                                                                                                                                   |
| 510 |      36.72590 |    204.181972 | Mattia Menchetti / Yan Wong                                                                                                                                  |
| 511 |     530.17078 |    414.134741 | Gareth Monger                                                                                                                                                |
| 512 |     465.98123 |    519.967101 | Chris huh                                                                                                                                                    |
| 513 |      22.51690 |      7.720162 | Chris huh                                                                                                                                                    |
| 514 |     585.60027 |    376.727868 | Iain Reid                                                                                                                                                    |
| 515 |     909.77207 |    668.207230 | T. Michael Keesey (after Walker & al.)                                                                                                                       |
| 516 |     865.67296 |     82.807322 | Margot Michaud                                                                                                                                               |
| 517 |     449.99629 |    665.273280 | David Orr                                                                                                                                                    |
| 518 |     139.05556 |    419.087738 | Chris huh                                                                                                                                                    |
| 519 |     841.87810 |    586.913892 | NA                                                                                                                                                           |
| 520 |      18.60615 |    432.702309 | Jaime Headden                                                                                                                                                |
| 521 |     932.21469 |    424.107252 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 522 |     760.08304 |    787.541218 | Margot Michaud                                                                                                                                               |

    #> Your tweet has been posted!
