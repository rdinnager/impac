
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immosaic

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/immosaic/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/immosaic/actions)
<!-- badges: end -->

The goal of `{immosaic}` is to create packed image mosaics. The main
function `immosaic`, takes a set of images, or a function that generates
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
devtools::install_github("rdinnager/immosaic")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(immosaic)
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

Now we feed our function to the `immosaic()` function, which packs the
generated images onto a canvas:

``` r
shapes <- immosaic(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
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

Now we run `immosaic` on our phylopic generating function:

``` r
phylopics <- immosaic(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Zimices, Arthur S. Brum, Ville Koistinen and T. Michael Keesey, Margot
Michaud, Dmitry Bogdanov (vectorized by T. Michael Keesey), Steven
Traver, Oscar Sanisidro, Scott Hartman, Alexandre Vong, Beth Reinke,
Noah Schlottman, photo from Casey Dunn, Andrew A. Farke, Tracy A. Heath,
T. Michael Keesey, Zachary Quigley, Siobhon Egan, Birgit Lang, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Gareth Monger,
Carlos Cano-Barbacil, Cesar Julian, T. Michael Keesey (vectorization)
and Larry Loos (photography), James R. Spotila and Ray Chatterji,
TaraTaylorDesign, Dean Schnabel, Jagged Fang Designs, Tauana J. Cunha,
Pranav Iyer (grey ideas), T. Michael Keesey (from a photograph by Frank
Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Alexis Simon,
Ferran Sayol, Matt Dempsey, Jaime Headden, Maija Karala, Elizabeth
Parker, Chris huh, Gabriela Palomo-Munoz, Raven Amos, Matt Crook, Sarah
Werning, Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey),
Michael Scroggie, Mathew Wedel, Roberto Díaz Sibaja, Nobu Tamura
(vectorized by T. Michael Keesey), Félix Landry Yuan, C. Camilo
Julián-Caballero, Mathieu Basille, Tasman Dixon, Myriam\_Ramirez,
Matthew E. Clapham, T. Michael Keesey (after Heinrich Harder), Charles
R. Knight, vectorized by Zimices, Tyler McCraney, Jaime Headden,
modified by T. Michael Keesey, E. J. Van Nieukerken, A. Laštuvka, and Z.
Laštuvka (vectorized by T. Michael Keesey), Noah Schlottman, L. Shyamal,
Julio Garza, Vijay Cavale (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, SecretJellyMan, Melissa Broussard, Greg
Schechter (original photo), Renato Santos (vector silhouette), DW Bapst
(modified from Bates et al., 2005), Melissa Ingala, Collin Gross, M
Kolmann, Sharon Wegner-Larsen, FunkMonk, Chloé Schmidt, Joanna Wolfe,
Michelle Site, Lani Mohan, Michael P. Taylor, Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette), Maxime
Dahirel, Iain Reid, Kai R. Caspar, Mercedes Yrayzoz (vectorized by T.
Michael Keesey), Scott Hartman, modified by T. Michael Keesey, NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), Lafage, Alexander Schmidt-Lebuhn, Lily Hughes,
Paul O. Lewis, Adam Stuart Smith (vectorized by T. Michael Keesey),
Jaime Headden (vectorized by T. Michael Keesey), Mali’o Kodis, drawing
by Manvir Singh, MPF (vectorized by T. Michael Keesey), Tom Tarrant
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Francisco Gascó (modified by Michael P. Taylor), Josep Marti
Solans, Margret Flinsch, vectorized by Zimices, Renato Santos, Nobu
Tamura (modified by T. Michael Keesey), Geoff Shaw, Henry Lydecker,
Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey),
Mathilde Cordellier, Griensteidl and T. Michael Keesey, Xavier
Giroux-Bougard, Terpsichores, Plukenet, Johan Lindgren, Michael W.
Caldwell, Takuya Konishi, Luis M. Chiappe, Hans Hillewaert (photo) and
T. Michael Keesey (vectorization), Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey), T.
Michael Keesey (after James & al.), Kenneth Lacovara (vectorized by T.
Michael Keesey), Caleb M. Brown, Birgit Lang; original image by
virmisco.org, S.Martini, Gabriele Midolo, Mali’o Kodis, image from
Brockhaus and Efron Encyclopedic Dictionary, CNZdenek, Kamil S. Jaron,
Nobu Tamura, vectorized by Zimices, Frederick William Frohawk
(vectorized by T. Michael Keesey), Jose Carlos Arenas-Monroy, Richard
Ruggiero, vectorized by Zimices, Filip em, Jon Hill, Dmitry Bogdanov,
Smokeybjb, Lukas Panzarin, Bennet McComish, photo by Hans Hillewaert,
Stuart Humphries, T. Michael Keesey (vectorization) and Nadiatalent
(photography), Paul Baker (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Jack Mayer Wood, Christine Axon,
wsnaccad, Felix Vaux, Dori <dori@merr.info> (source photo) and Nevit
Dilmen, Joedison Rocha, Eric Moody, Mali’o Kodis, photograph by Bruno
Vellutini, Pearson Scott Foresman (vectorized by T. Michael Keesey),
Martin R. Smith, Neil Kelley, Rebecca Groom, Yan Wong from wikipedia
drawing (PD: Pearson Scott Foresman), Lankester Edwin Ray (vectorized by
T. Michael Keesey), Sean McCann, FunkMonk (Michael B.H.; vectorized by
T. Michael Keesey), G. M. Woodward, Matt Martyniuk, Robert Gay, modified
from FunkMonk (Michael B.H.) and T. Michael Keesey., Timothy Knepp
(vectorized by T. Michael Keesey), Maxwell Lefroy (vectorized by T.
Michael Keesey), Chase Brownstein, Conty, Yusan Yang, Zimices, based in
Mauricio Antón skeletal, Lukasiniho, Rebecca Groom (Based on Photo by
Andreas Trepte), Original drawing by Nobu Tamura, vectorized by Roberto
Díaz Sibaja, Armin Reindl, Remes K, Ortega F, Fierro I, Joger U, Kosma
R, et al., Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong),
Christoph Schomburg, Caroline Harding, MAF (vectorized by T. Michael
Keesey), Rene Martin, Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, Walter
Vladimir, Conty (vectorized by T. Michael Keesey), Emily Jane McTavish,
Milton Tan, Benjamin Monod-Broca, Kailah Thorn & Mark Hutchinson, James
I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel,
and Jelle P. Wiersma (vectorized by T. Michael Keesey), Yan Wong from
photo by Denes Emoke, Darren Naish (vectorized by T. Michael Keesey),
Todd Marshall, vectorized by Zimices, Ghedoghedo, Ernst Haeckel
(vectorized by T. Michael Keesey), T. Michael Keesey (after
Ponomarenko), Mattia Menchetti, Jaime A. Headden (vectorized by T.
Michael Keesey), DW Bapst (modified from Bulman, 1970), Harold N Eyster

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     397.94582 |    149.203898 | Zimices                                                                                                                                                               |
|   2 |     148.25838 |    622.917863 | Arthur S. Brum                                                                                                                                                        |
|   3 |     381.05504 |    235.778171 | Zimices                                                                                                                                                               |
|   4 |     549.78264 |    219.495790 | Zimices                                                                                                                                                               |
|   5 |     732.47450 |    443.714092 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
|   6 |     678.12985 |    294.220290 | Margot Michaud                                                                                                                                                        |
|   7 |     962.42064 |    606.718058 | Margot Michaud                                                                                                                                                        |
|   8 |     373.13866 |    408.950313 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|   9 |     667.65458 |    659.949846 | Margot Michaud                                                                                                                                                        |
|  10 |     311.08888 |    643.053534 | Steven Traver                                                                                                                                                         |
|  11 |     201.39592 |    286.076291 | Oscar Sanisidro                                                                                                                                                       |
|  12 |     607.46930 |    762.384820 | Scott Hartman                                                                                                                                                         |
|  13 |     294.94316 |    338.216368 | Alexandre Vong                                                                                                                                                        |
|  14 |     390.41754 |     60.436025 | Margot Michaud                                                                                                                                                        |
|  15 |     264.37882 |     92.057540 | Beth Reinke                                                                                                                                                           |
|  16 |     902.25184 |    159.252857 | NA                                                                                                                                                                    |
|  17 |     495.92287 |     96.842924 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
|  18 |     768.07998 |    539.942327 | Andrew A. Farke                                                                                                                                                       |
|  19 |     102.15453 |    753.462409 | Tracy A. Heath                                                                                                                                                        |
|  20 |     174.21257 |    520.721231 | T. Michael Keesey                                                                                                                                                     |
|  21 |     616.73937 |    573.773200 | Zachary Quigley                                                                                                                                                       |
|  22 |     520.32943 |    380.371442 | Margot Michaud                                                                                                                                                        |
|  23 |     545.51141 |    630.994284 | Scott Hartman                                                                                                                                                         |
|  24 |      80.94683 |    372.419395 | Siobhon Egan                                                                                                                                                          |
|  25 |     609.03678 |     34.216340 | Birgit Lang                                                                                                                                                           |
|  26 |     468.52612 |    503.411514 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  27 |     826.33199 |    663.229784 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                 |
|  28 |     940.52709 |    460.510699 | Gareth Monger                                                                                                                                                         |
|  29 |     110.40589 |    289.741178 | Zimices                                                                                                                                                               |
|  30 |     670.85160 |    158.336149 | Carlos Cano-Barbacil                                                                                                                                                  |
|  31 |     934.65979 |    717.427000 | NA                                                                                                                                                                    |
|  32 |      32.27743 |    101.109625 | T. Michael Keesey                                                                                                                                                     |
|  33 |     132.40854 |    174.302625 | Cesar Julian                                                                                                                                                          |
|  34 |     473.90161 |    262.850783 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
|  35 |      67.76923 |    463.273914 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  36 |     243.30891 |    452.099266 | TaraTaylorDesign                                                                                                                                                      |
|  37 |     773.09587 |    590.351400 | Dean Schnabel                                                                                                                                                         |
|  38 |      90.58546 |    341.254641 | Jagged Fang Designs                                                                                                                                                   |
|  39 |     731.21475 |    350.901311 | Tauana J. Cunha                                                                                                                                                       |
|  40 |     351.15048 |    495.284273 | Tauana J. Cunha                                                                                                                                                       |
|  41 |     337.40274 |    752.373961 | Scott Hartman                                                                                                                                                         |
|  42 |     286.54106 |     46.978852 | Pranav Iyer (grey ideas)                                                                                                                                              |
|  43 |     785.35564 |     36.201853 | Zimices                                                                                                                                                               |
|  44 |     849.97839 |    328.376318 | Birgit Lang                                                                                                                                                           |
|  45 |     717.30502 |    218.448061 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
|  46 |     150.11449 |     95.149206 | Alexis Simon                                                                                                                                                          |
|  47 |     211.62958 |    728.181516 | Ferran Sayol                                                                                                                                                          |
|  48 |     874.26188 |    420.695127 | Ferran Sayol                                                                                                                                                          |
|  49 |      82.24272 |    676.758994 | Scott Hartman                                                                                                                                                         |
|  50 |     692.11680 |     79.030489 | Matt Dempsey                                                                                                                                                          |
|  51 |     309.57053 |    208.313443 | Jaime Headden                                                                                                                                                         |
|  52 |     599.97653 |    519.985614 | Maija Karala                                                                                                                                                          |
|  53 |     624.03633 |    449.711535 | Elizabeth Parker                                                                                                                                                      |
|  54 |     475.77896 |    683.729824 | Gareth Monger                                                                                                                                                         |
|  55 |     396.21399 |    312.686702 | Chris huh                                                                                                                                                             |
|  56 |      74.00971 |    221.784301 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  57 |     392.31626 |    577.339546 | Carlos Cano-Barbacil                                                                                                                                                  |
|  58 |     178.83855 |    660.918977 | Raven Amos                                                                                                                                                            |
|  59 |     928.92118 |    303.299582 | Steven Traver                                                                                                                                                         |
|  60 |     348.12629 |     19.972330 | NA                                                                                                                                                                    |
|  61 |     105.55324 |    527.784662 | Matt Crook                                                                                                                                                            |
|  62 |     294.34562 |    540.756065 | Chris huh                                                                                                                                                             |
|  63 |     836.21617 |    772.758615 | Sarah Werning                                                                                                                                                         |
|  64 |     610.11653 |    710.605286 | Zimices                                                                                                                                                               |
|  65 |     739.53942 |    726.857637 | Steven Traver                                                                                                                                                         |
|  66 |     567.62408 |    133.376754 | Steven Traver                                                                                                                                                         |
|  67 |    1004.20276 |    385.428690 | T. Michael Keesey                                                                                                                                                     |
|  68 |     885.27911 |    519.583706 | T. Michael Keesey                                                                                                                                                     |
|  69 |     296.25864 |    778.929954 | NA                                                                                                                                                                    |
|  70 |     942.67287 |     63.876320 | Steven Traver                                                                                                                                                         |
|  71 |     133.48533 |    411.294719 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
|  72 |     777.24104 |    114.595493 | Michael Scroggie                                                                                                                                                      |
|  73 |     440.33641 |    616.552989 | Mathew Wedel                                                                                                                                                          |
|  74 |     851.27921 |    475.638393 | Margot Michaud                                                                                                                                                        |
|  75 |     827.12464 |    394.847119 | Steven Traver                                                                                                                                                         |
|  76 |     647.97002 |    235.788462 | Roberto Díaz Sibaja                                                                                                                                                   |
|  77 |     390.28195 |    343.166286 | Chris huh                                                                                                                                                             |
|  78 |     743.64015 |    787.361309 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  79 |     512.62621 |     73.612751 | Félix Landry Yuan                                                                                                                                                     |
|  80 |     529.21732 |    467.544101 | Birgit Lang                                                                                                                                                           |
|  81 |     482.92018 |    785.014181 | C. Camilo Julián-Caballero                                                                                                                                            |
|  82 |     300.94825 |    269.990142 | Maija Karala                                                                                                                                                          |
|  83 |      41.26502 |    619.627237 | Mathieu Basille                                                                                                                                                       |
|  84 |     175.34872 |    367.850603 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  85 |     573.50441 |    288.172125 | Tasman Dixon                                                                                                                                                          |
|  86 |      27.53482 |    747.291385 | T. Michael Keesey                                                                                                                                                     |
|  87 |     446.78901 |    704.429675 | Myriam\_Ramirez                                                                                                                                                       |
|  88 |     617.09420 |    380.050754 | Maija Karala                                                                                                                                                          |
|  89 |     265.05612 |    171.259430 | Scott Hartman                                                                                                                                                         |
|  90 |     550.84148 |     39.293578 | Matthew E. Clapham                                                                                                                                                    |
|  91 |     512.07465 |    697.091638 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
|  92 |     185.18462 |    217.722707 | Scott Hartman                                                                                                                                                         |
|  93 |     599.10070 |     81.832800 | Ferran Sayol                                                                                                                                                          |
|  94 |     694.40721 |    770.658004 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
|  95 |      52.39449 |    520.296469 | Tyler McCraney                                                                                                                                                        |
|  96 |     249.76673 |    260.743914 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
|  97 |     507.28566 |    673.423328 | T. Michael Keesey                                                                                                                                                     |
|  98 |     912.89453 |    563.130568 | Chris huh                                                                                                                                                             |
|  99 |     863.33068 |    716.800098 | Gareth Monger                                                                                                                                                         |
| 100 |     986.94417 |    744.472005 | NA                                                                                                                                                                    |
| 101 |     433.38489 |    764.968617 | Steven Traver                                                                                                                                                         |
| 102 |     951.97456 |    382.876552 | Tasman Dixon                                                                                                                                                          |
| 103 |     427.24689 |    432.157127 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |
| 104 |     947.83807 |    351.946690 | Noah Schlottman                                                                                                                                                       |
| 105 |     880.92560 |    218.682746 | Margot Michaud                                                                                                                                                        |
| 106 |     745.50324 |    493.692876 | Scott Hartman                                                                                                                                                         |
| 107 |      89.41485 |     69.863206 | L. Shyamal                                                                                                                                                            |
| 108 |     774.89955 |    183.535458 | Julio Garza                                                                                                                                                           |
| 109 |     142.15345 |    206.414103 | Cesar Julian                                                                                                                                                          |
| 110 |     841.29352 |     48.616140 | Margot Michaud                                                                                                                                                        |
| 111 |     862.84361 |    577.364902 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 112 |     237.72799 |    506.605181 | SecretJellyMan                                                                                                                                                        |
| 113 |     601.00276 |    598.704853 | Melissa Broussard                                                                                                                                                     |
| 114 |     544.90503 |    576.488852 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                    |
| 115 |     895.21028 |    683.031701 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
| 116 |      24.72548 |    248.038566 | Jagged Fang Designs                                                                                                                                                   |
| 117 |     264.61080 |    653.295161 | Melissa Ingala                                                                                                                                                        |
| 118 |     970.82648 |    685.270883 | Collin Gross                                                                                                                                                          |
| 119 |     966.82030 |    522.882479 | Chris huh                                                                                                                                                             |
| 120 |      97.19756 |     19.113138 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 121 |      86.92468 |    125.075136 | Gareth Monger                                                                                                                                                         |
| 122 |     819.69251 |    255.165293 | Margot Michaud                                                                                                                                                        |
| 123 |     602.33246 |    270.095427 | T. Michael Keesey                                                                                                                                                     |
| 124 |     785.68840 |    253.187768 | M Kolmann                                                                                                                                                             |
| 125 |     259.57418 |    295.842912 | Sharon Wegner-Larsen                                                                                                                                                  |
| 126 |     943.65783 |    554.578378 | T. Michael Keesey                                                                                                                                                     |
| 127 |     784.65362 |    774.073751 | FunkMonk                                                                                                                                                              |
| 128 |     430.47265 |    733.109026 | Chloé Schmidt                                                                                                                                                         |
| 129 |     443.09197 |    340.706813 | Joanna Wolfe                                                                                                                                                          |
| 130 |     998.61922 |    270.404091 | Chris huh                                                                                                                                                             |
| 131 |     701.58460 |     34.371720 | Margot Michaud                                                                                                                                                        |
| 132 |     642.34401 |    361.703137 | Chris huh                                                                                                                                                             |
| 133 |     192.69812 |     12.002209 | Gareth Monger                                                                                                                                                         |
| 134 |     274.87506 |    580.470618 | Scott Hartman                                                                                                                                                         |
| 135 |     957.73643 |    259.870249 | Matt Crook                                                                                                                                                            |
| 136 |     774.08194 |    327.225238 | Michelle Site                                                                                                                                                         |
| 137 |     566.96916 |    676.674989 | Lani Mohan                                                                                                                                                            |
| 138 |    1006.53084 |    775.053463 | Zimices                                                                                                                                                               |
| 139 |     929.68003 |    785.256390 | Zimices                                                                                                                                                               |
| 140 |     129.66722 |    353.617238 | Michael P. Taylor                                                                                                                                                     |
| 141 |     351.45116 |    269.929486 | NA                                                                                                                                                                    |
| 142 |     712.45948 |    678.462457 | Ferran Sayol                                                                                                                                                          |
| 143 |     785.11440 |    421.224196 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 144 |     948.19169 |    435.546939 | Oscar Sanisidro                                                                                                                                                       |
| 145 |     114.04004 |    582.515392 | Maxime Dahirel                                                                                                                                                        |
| 146 |     713.17692 |    519.995540 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 147 |     836.13563 |    228.188543 | Margot Michaud                                                                                                                                                        |
| 148 |    1005.92837 |     32.487283 | L. Shyamal                                                                                                                                                            |
| 149 |     345.37654 |    734.782692 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 150 |     367.16911 |    771.186883 | Matt Crook                                                                                                                                                            |
| 151 |     401.05851 |    186.317839 | Andrew A. Farke                                                                                                                                                       |
| 152 |     189.53628 |    457.967213 | Iain Reid                                                                                                                                                             |
| 153 |     292.31318 |    470.809503 | Kai R. Caspar                                                                                                                                                         |
| 154 |     542.05822 |    121.395903 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 155 |     492.41393 |    757.734089 | L. Shyamal                                                                                                                                                            |
| 156 |     825.62667 |    356.628343 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 157 |     659.04165 |    471.824454 | Ferran Sayol                                                                                                                                                          |
| 158 |     396.16334 |    203.015422 | Scott Hartman                                                                                                                                                         |
| 159 |     509.28698 |    583.295015 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 160 |     822.63701 |    343.930682 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 161 |      25.53521 |    294.989790 | Matt Crook                                                                                                                                                            |
| 162 |     396.53445 |    282.411511 | Lafage                                                                                                                                                                |
| 163 |     430.49719 |    524.308636 | Scott Hartman                                                                                                                                                         |
| 164 |     758.16716 |    314.911053 | Maija Karala                                                                                                                                                          |
| 165 |     465.95370 |    139.286417 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 166 |     670.30118 |    278.413283 | Dean Schnabel                                                                                                                                                         |
| 167 |     425.54218 |    541.961471 | Sarah Werning                                                                                                                                                         |
| 168 |     972.06564 |     18.979416 | Margot Michaud                                                                                                                                                        |
| 169 |       4.86784 |    693.668718 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 170 |     379.50084 |    114.961762 | Zimices                                                                                                                                                               |
| 171 |     649.18291 |    119.664564 | Lily Hughes                                                                                                                                                           |
| 172 |    1001.73424 |    202.345738 | Paul O. Lewis                                                                                                                                                         |
| 173 |     834.32324 |    437.156463 | Gareth Monger                                                                                                                                                         |
| 174 |     511.44825 |    300.613085 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
| 175 |     526.52310 |    723.794929 | NA                                                                                                                                                                    |
| 176 |     142.14286 |    547.740472 | Zimices                                                                                                                                                               |
| 177 |     471.87230 |    468.939316 | Ferran Sayol                                                                                                                                                          |
| 178 |     655.74081 |    602.021204 | Gareth Monger                                                                                                                                                         |
| 179 |     257.25801 |    742.862338 | Matt Crook                                                                                                                                                            |
| 180 |     551.62331 |    316.897609 | Chris huh                                                                                                                                                             |
| 181 |     694.22952 |    546.773918 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 182 |     867.52666 |    258.422833 | Matt Crook                                                                                                                                                            |
| 183 |     316.16550 |    421.410691 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 184 |     613.46218 |    672.728192 | Steven Traver                                                                                                                                                         |
| 185 |    1000.11268 |    712.744171 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 186 |     622.54838 |     83.590477 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 187 |     234.20705 |    212.109042 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 188 |     448.58368 |    373.572157 | Kai R. Caspar                                                                                                                                                         |
| 189 |     427.45160 |    454.890790 | Jaime Headden                                                                                                                                                         |
| 190 |     895.93483 |    576.294010 | Margot Michaud                                                                                                                                                        |
| 191 |      51.68903 |    644.466548 | Margot Michaud                                                                                                                                                        |
| 192 |     308.04947 |    579.901066 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 193 |     321.05115 |     65.708314 | Josep Marti Solans                                                                                                                                                    |
| 194 |      48.92257 |    262.971573 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 195 |     334.37052 |    687.281022 | Renato Santos                                                                                                                                                         |
| 196 |     452.19001 |     37.015973 | Margot Michaud                                                                                                                                                        |
| 197 |     788.02557 |    312.774828 | Michelle Site                                                                                                                                                         |
| 198 |      75.01111 |    238.967554 | Chris huh                                                                                                                                                             |
| 199 |     565.52332 |    724.427223 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 200 |     709.55861 |    600.386705 | Gareth Monger                                                                                                                                                         |
| 201 |     442.38419 |    106.736697 | Geoff Shaw                                                                                                                                                            |
| 202 |      22.38696 |    490.408521 | Chris huh                                                                                                                                                             |
| 203 |     423.60023 |    659.100324 | Margot Michaud                                                                                                                                                        |
| 204 |     240.97519 |    673.760634 | Ferran Sayol                                                                                                                                                          |
| 205 |      96.92278 |    702.229738 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 206 |     720.73481 |    278.618798 | Zimices                                                                                                                                                               |
| 207 |     986.91014 |    487.101354 | Scott Hartman                                                                                                                                                         |
| 208 |     928.78894 |    517.187786 | Henry Lydecker                                                                                                                                                        |
| 209 |     713.64699 |    393.391478 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 210 |     713.19724 |    262.036055 | Margot Michaud                                                                                                                                                        |
| 211 |     318.37183 |    135.536337 | Steven Traver                                                                                                                                                         |
| 212 |     972.36552 |    783.865089 | Mathilde Cordellier                                                                                                                                                   |
| 213 |     745.42354 |    650.905852 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 214 |     971.59186 |    711.080971 | Xavier Giroux-Bougard                                                                                                                                                 |
| 215 |     652.36935 |    780.437169 | Terpsichores                                                                                                                                                          |
| 216 |     197.57161 |    140.709774 | Maxime Dahirel                                                                                                                                                        |
| 217 |     332.61653 |    109.687143 | Zimices                                                                                                                                                               |
| 218 |      18.05611 |    391.637643 | Ferran Sayol                                                                                                                                                          |
| 219 |     173.30200 |    440.547271 | NA                                                                                                                                                                    |
| 220 |     577.38888 |    438.493554 | Ferran Sayol                                                                                                                                                          |
| 221 |     351.74873 |    363.355275 | Zimices                                                                                                                                                               |
| 222 |     764.56218 |    144.750630 | Plukenet                                                                                                                                                              |
| 223 |     240.12134 |    193.026477 | Jagged Fang Designs                                                                                                                                                   |
| 224 |    1003.18697 |     97.723917 | Steven Traver                                                                                                                                                         |
| 225 |     604.62933 |    548.029181 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 226 |     290.95823 |    520.518873 | Jagged Fang Designs                                                                                                                                                   |
| 227 |     935.84298 |     13.935954 | Ferran Sayol                                                                                                                                                          |
| 228 |    1002.30491 |    309.743843 | Gareth Monger                                                                                                                                                         |
| 229 |      71.22170 |    532.372348 | Scott Hartman                                                                                                                                                         |
| 230 |     644.42622 |    540.420045 | NA                                                                                                                                                                    |
| 231 |     812.34991 |    172.215558 | Zimices                                                                                                                                                               |
| 232 |     790.82914 |    558.930155 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 233 |     465.44730 |    325.997740 | T. Michael Keesey                                                                                                                                                     |
| 234 |     762.81241 |     83.464114 | Jagged Fang Designs                                                                                                                                                   |
| 235 |     985.24966 |    437.177601 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 236 |      88.03454 |    594.737556 | Matt Crook                                                                                                                                                            |
| 237 |      45.76387 |    787.609344 | Margot Michaud                                                                                                                                                        |
| 238 |     913.98305 |    544.795153 | Noah Schlottman                                                                                                                                                       |
| 239 |     167.52348 |    390.682551 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 240 |      50.22380 |    406.557955 | T. Michael Keesey                                                                                                                                                     |
| 241 |     570.22053 |    351.507323 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 242 |     742.35415 |    354.075750 | Caleb M. Brown                                                                                                                                                        |
| 243 |     207.68294 |    194.817820 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 244 |     456.41414 |     96.247865 | Margot Michaud                                                                                                                                                        |
| 245 |     995.31664 |    246.466652 | NA                                                                                                                                                                    |
| 246 |     736.78383 |    366.601093 | Ferran Sayol                                                                                                                                                          |
| 247 |     891.04604 |      5.942481 | Mathew Wedel                                                                                                                                                          |
| 248 |     460.30301 |     67.338603 | Birgit Lang                                                                                                                                                           |
| 249 |     487.01544 |     10.709991 | S.Martini                                                                                                                                                             |
| 250 |      38.63082 |    273.829189 | Chris huh                                                                                                                                                             |
| 251 |     265.01148 |    711.454254 | Gareth Monger                                                                                                                                                         |
| 252 |     301.01213 |    143.273994 | Gabriele Midolo                                                                                                                                                       |
| 253 |      81.84456 |     26.810062 | Ferran Sayol                                                                                                                                                          |
| 254 |     533.74292 |    766.597842 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 255 |     629.43629 |    104.906029 | Matt Crook                                                                                                                                                            |
| 256 |     808.28417 |    276.983383 | Matt Crook                                                                                                                                                            |
| 257 |     289.76370 |    558.543467 | CNZdenek                                                                                                                                                              |
| 258 |     475.21532 |    176.537424 | Kamil S. Jaron                                                                                                                                                        |
| 259 |     983.23189 |    109.137379 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 260 |     848.81601 |    292.351312 | Tasman Dixon                                                                                                                                                          |
| 261 |     808.37384 |    444.538589 | Ferran Sayol                                                                                                                                                          |
| 262 |     735.68015 |    102.576441 | Zimices                                                                                                                                                               |
| 263 |     319.23853 |    450.949616 | Matt Crook                                                                                                                                                            |
| 264 |     431.15819 |    190.909566 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 265 |     885.70012 |    726.317985 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 266 |     823.38111 |    135.312789 | Matt Crook                                                                                                                                                            |
| 267 |     587.05547 |    483.959775 | Zimices                                                                                                                                                               |
| 268 |     309.80485 |    733.435394 | Scott Hartman                                                                                                                                                         |
| 269 |     531.62373 |    790.520787 | Gareth Monger                                                                                                                                                         |
| 270 |     587.02023 |    413.450658 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 271 |     112.03351 |    660.049897 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 272 |     855.49025 |    201.961751 | Matt Crook                                                                                                                                                            |
| 273 |     506.75812 |    275.605972 | Ferran Sayol                                                                                                                                                          |
| 274 |     383.93379 |     91.582651 | T. Michael Keesey                                                                                                                                                     |
| 275 |     235.56600 |    243.909736 | Filip em                                                                                                                                                              |
| 276 |     180.91871 |    596.945600 | Gareth Monger                                                                                                                                                         |
| 277 |     182.11287 |    767.379003 | Jon Hill                                                                                                                                                              |
| 278 |      33.62770 |    705.839683 | Dmitry Bogdanov                                                                                                                                                       |
| 279 |     946.12506 |    323.777521 | Matt Crook                                                                                                                                                            |
| 280 |     624.37923 |     41.919188 | T. Michael Keesey                                                                                                                                                     |
| 281 |     199.62936 |     39.630172 | Smokeybjb                                                                                                                                                             |
| 282 |     905.58747 |    256.099287 | Lukas Panzarin                                                                                                                                                        |
| 283 |     316.37008 |    162.849968 | L. Shyamal                                                                                                                                                            |
| 284 |     553.38504 |     14.705801 | Margot Michaud                                                                                                                                                        |
| 285 |     741.94516 |    248.116905 | T. Michael Keesey                                                                                                                                                     |
| 286 |     209.55346 |    388.719404 | Melissa Broussard                                                                                                                                                     |
| 287 |     119.77676 |     20.688128 | T. Michael Keesey                                                                                                                                                     |
| 288 |     970.40507 |    505.733042 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 289 |     799.80360 |    344.703558 | Stuart Humphries                                                                                                                                                      |
| 290 |     752.48173 |    678.719356 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 291 |    1003.51960 |    679.080843 | NA                                                                                                                                                                    |
| 292 |     278.93902 |    240.421707 | Scott Hartman                                                                                                                                                         |
| 293 |     759.59056 |    411.222115 | Kamil S. Jaron                                                                                                                                                        |
| 294 |    1008.12858 |    454.154576 | Birgit Lang                                                                                                                                                           |
| 295 |      25.18341 |    580.764651 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 296 |     256.96150 |    132.043116 | Dean Schnabel                                                                                                                                                         |
| 297 |     685.95625 |    426.871580 | Birgit Lang                                                                                                                                                           |
| 298 |     820.87539 |    570.197672 | NA                                                                                                                                                                    |
| 299 |      17.76827 |    353.016497 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 300 |     682.08317 |    634.230067 | Sarah Werning                                                                                                                                                         |
| 301 |     976.23044 |    163.562196 | Ferran Sayol                                                                                                                                                          |
| 302 |     470.35807 |    435.318934 | Tasman Dixon                                                                                                                                                          |
| 303 |      39.84299 |    346.055763 | Jack Mayer Wood                                                                                                                                                       |
| 304 |      66.60616 |    716.430610 | Gareth Monger                                                                                                                                                         |
| 305 |     808.18239 |    241.041699 | Christine Axon                                                                                                                                                        |
| 306 |     689.85562 |    290.034362 | NA                                                                                                                                                                    |
| 307 |      36.30355 |    690.437875 | Zimices                                                                                                                                                               |
| 308 |     593.04059 |    791.149116 | wsnaccad                                                                                                                                                              |
| 309 |     203.84726 |     26.765280 | Margot Michaud                                                                                                                                                        |
| 310 |     917.60615 |    587.502193 | NA                                                                                                                                                                    |
| 311 |     676.28498 |    484.976337 | Mathilde Cordellier                                                                                                                                                   |
| 312 |     446.97133 |    400.674477 | NA                                                                                                                                                                    |
| 313 |      66.33703 |    554.990876 | Kamil S. Jaron                                                                                                                                                        |
| 314 |     292.35352 |    513.740001 | Gareth Monger                                                                                                                                                         |
| 315 |     135.47803 |    705.253495 | Matt Crook                                                                                                                                                            |
| 316 |     213.97673 |    541.565712 | Felix Vaux                                                                                                                                                            |
| 317 |     892.48961 |     69.281543 | Sharon Wegner-Larsen                                                                                                                                                  |
| 318 |     131.18517 |    241.608132 | S.Martini                                                                                                                                                             |
| 319 |      23.47018 |    534.368646 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 320 |     396.60114 |    782.719952 | NA                                                                                                                                                                    |
| 321 |     261.76192 |    323.915993 | Zimices                                                                                                                                                               |
| 322 |     943.28330 |    648.312195 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 323 |      27.71332 |    467.823021 | C. Camilo Julián-Caballero                                                                                                                                            |
| 324 |     824.90625 |    295.010242 | T. Michael Keesey                                                                                                                                                     |
| 325 |     657.68258 |    256.329121 | Roberto Díaz Sibaja                                                                                                                                                   |
| 326 |     128.53042 |    395.364710 | Xavier Giroux-Bougard                                                                                                                                                 |
| 327 |     383.23762 |    714.379779 | Joedison Rocha                                                                                                                                                        |
| 328 |     820.56770 |    476.834184 | Jagged Fang Designs                                                                                                                                                   |
| 329 |     635.75692 |    270.746932 | Zimices                                                                                                                                                               |
| 330 |     251.43909 |    636.498109 | Tasman Dixon                                                                                                                                                          |
| 331 |     842.00584 |    597.721693 | Eric Moody                                                                                                                                                            |
| 332 |     333.49557 |    577.983346 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 333 |      18.58600 |    323.249935 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 334 |     451.86520 |     16.628799 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 335 |     210.22542 |    504.425438 | Steven Traver                                                                                                                                                         |
| 336 |     553.09114 |    305.348173 | Martin R. Smith                                                                                                                                                       |
| 337 |     637.10388 |    673.124628 | Gareth Monger                                                                                                                                                         |
| 338 |     724.98753 |    116.223648 | Margot Michaud                                                                                                                                                        |
| 339 |    1012.61335 |    119.798892 | Margot Michaud                                                                                                                                                        |
| 340 |     101.23573 |    535.457843 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 341 |     701.94597 |    792.345864 | Neil Kelley                                                                                                                                                           |
| 342 |     432.27905 |    558.463707 | Tasman Dixon                                                                                                                                                          |
| 343 |     467.34034 |    198.920155 | Steven Traver                                                                                                                                                         |
| 344 |     884.51357 |    310.227114 | Rebecca Groom                                                                                                                                                         |
| 345 |     231.76794 |    623.266440 | Tracy A. Heath                                                                                                                                                        |
| 346 |     616.68991 |    228.685737 | Gareth Monger                                                                                                                                                         |
| 347 |     715.07076 |    131.734205 | Zimices                                                                                                                                                               |
| 348 |     679.49540 |    508.730048 | Chris huh                                                                                                                                                             |
| 349 |     621.67826 |    774.193182 | T. Michael Keesey                                                                                                                                                     |
| 350 |     180.49865 |    677.348599 | Scott Hartman                                                                                                                                                         |
| 351 |     154.43486 |     26.963707 | Chris huh                                                                                                                                                             |
| 352 |      68.71661 |    249.229612 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 353 |     398.93445 |    737.043300 | Dean Schnabel                                                                                                                                                         |
| 354 |     699.81819 |    613.550219 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 355 |     798.31953 |    411.059358 | Scott Hartman                                                                                                                                                         |
| 356 |     675.63410 |    524.195654 | Sean McCann                                                                                                                                                           |
| 357 |      80.94813 |    656.795343 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 358 |     389.20657 |    557.453341 | Jaime Headden                                                                                                                                                         |
| 359 |     828.42016 |    213.170586 | G. M. Woodward                                                                                                                                                        |
| 360 |     689.98117 |    560.088555 | Birgit Lang                                                                                                                                                           |
| 361 |     243.33918 |    379.812339 | Matt Martyniuk                                                                                                                                                        |
| 362 |     551.86112 |     94.830221 | NA                                                                                                                                                                    |
| 363 |     171.84419 |    342.814601 | Gareth Monger                                                                                                                                                         |
| 364 |     941.70595 |    415.770950 | NA                                                                                                                                                                    |
| 365 |     372.25863 |    217.668259 | Chris huh                                                                                                                                                             |
| 366 |     588.59403 |    677.979050 | NA                                                                                                                                                                    |
| 367 |     416.41595 |    401.410414 | Caleb M. Brown                                                                                                                                                        |
| 368 |     160.36871 |    462.737705 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 369 |     863.94700 |      9.725063 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 370 |     925.61204 |    441.111922 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 371 |     429.29766 |    794.712216 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 372 |     656.09026 |    343.972855 | Chase Brownstein                                                                                                                                                      |
| 373 |     301.18984 |    183.276044 | Margot Michaud                                                                                                                                                        |
| 374 |     513.23564 |     19.878466 | Ferran Sayol                                                                                                                                                          |
| 375 |      20.70095 |    652.316600 | Carlos Cano-Barbacil                                                                                                                                                  |
| 376 |      67.13103 |     54.939475 | L. Shyamal                                                                                                                                                            |
| 377 |      18.83402 |    790.711665 | Zimices                                                                                                                                                               |
| 378 |     243.91234 |    118.585255 | Zimices                                                                                                                                                               |
| 379 |     881.51368 |    377.486114 | Jaime Headden                                                                                                                                                         |
| 380 |     429.01725 |     25.917138 | NA                                                                                                                                                                    |
| 381 |     286.01795 |    295.762617 | Conty                                                                                                                                                                 |
| 382 |     137.89111 |    572.708453 | Sarah Werning                                                                                                                                                         |
| 383 |     830.15306 |    498.989603 | Tasman Dixon                                                                                                                                                          |
| 384 |     610.54262 |    282.454574 | NA                                                                                                                                                                    |
| 385 |     197.32747 |    100.238124 | Margot Michaud                                                                                                                                                        |
| 386 |     680.54635 |     23.490800 | Jagged Fang Designs                                                                                                                                                   |
| 387 |      39.86638 |    311.675641 | Yusan Yang                                                                                                                                                            |
| 388 |     478.82720 |    581.522483 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
| 389 |     920.54122 |    654.023903 | NA                                                                                                                                                                    |
| 390 |     953.46740 |    581.625566 | Gareth Monger                                                                                                                                                         |
| 391 |     793.21946 |    384.775634 | M Kolmann                                                                                                                                                             |
| 392 |     487.12432 |    543.746777 | Margot Michaud                                                                                                                                                        |
| 393 |     446.19814 |    166.689405 | Zimices                                                                                                                                                               |
| 394 |      58.47427 |    394.476767 | Sarah Werning                                                                                                                                                         |
| 395 |     997.32951 |    494.147373 | Margot Michaud                                                                                                                                                        |
| 396 |     177.23470 |    635.251284 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 397 |     895.64351 |    461.242329 | Joanna Wolfe                                                                                                                                                          |
| 398 |     747.80939 |    263.080932 | Tracy A. Heath                                                                                                                                                        |
| 399 |     280.34116 |    569.531587 | Michael Scroggie                                                                                                                                                      |
| 400 |     689.05039 |      6.785739 | Zimices                                                                                                                                                               |
| 401 |     496.60621 |    236.595842 | Dean Schnabel                                                                                                                                                         |
| 402 |     232.81148 |    226.909392 | Lukasiniho                                                                                                                                                            |
| 403 |     864.24028 |    747.435955 | Jagged Fang Designs                                                                                                                                                   |
| 404 |      31.23202 |    504.931145 | Zimices                                                                                                                                                               |
| 405 |     887.29442 |    633.973416 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 406 |     995.24777 |    225.128746 | Scott Hartman                                                                                                                                                         |
| 407 |     470.77733 |    155.723595 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 408 |     800.41840 |     80.321909 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 409 |      57.26683 |     89.522207 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 410 |     253.65912 |     12.573183 | Scott Hartman                                                                                                                                                         |
| 411 |     506.88201 |    773.184273 | NA                                                                                                                                                                    |
| 412 |     432.80318 |    261.379531 | Chris huh                                                                                                                                                             |
| 413 |     375.02359 |      3.670495 | Gareth Monger                                                                                                                                                         |
| 414 |     138.61116 |    438.752505 | Maija Karala                                                                                                                                                          |
| 415 |     194.62103 |     73.258506 | Armin Reindl                                                                                                                                                          |
| 416 |     223.52102 |    778.452710 | Zimices                                                                                                                                                               |
| 417 |     514.11280 |    575.000801 | Iain Reid                                                                                                                                                             |
| 418 |     167.41752 |    792.666392 | Scott Hartman                                                                                                                                                         |
| 419 |     418.21380 |    562.916676 | Jagged Fang Designs                                                                                                                                                   |
| 420 |     350.76282 |     95.167702 | Jagged Fang Designs                                                                                                                                                   |
| 421 |     204.33434 |    350.177357 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 422 |     330.81660 |    557.569328 | Jaime Headden                                                                                                                                                         |
| 423 |     405.62665 |    251.389864 | Scott Hartman                                                                                                                                                         |
| 424 |     434.92466 |    246.267998 | Matt Martyniuk                                                                                                                                                        |
| 425 |     233.45346 |    153.553210 | Jaime Headden                                                                                                                                                         |
| 426 |     500.90092 |    657.333475 | Zimices                                                                                                                                                               |
| 427 |     798.39203 |    159.088347 | Chris huh                                                                                                                                                             |
| 428 |      82.21732 |    666.197333 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 429 |     684.92708 |    115.401989 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 430 |    1017.18739 |    261.181581 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 431 |     182.81338 |    778.472642 | Tasman Dixon                                                                                                                                                          |
| 432 |     460.32204 |    645.681161 | Martin R. Smith                                                                                                                                                       |
| 433 |     679.51115 |    382.527318 | Matt Crook                                                                                                                                                            |
| 434 |     365.85278 |    554.624760 | Melissa Broussard                                                                                                                                                     |
| 435 |     619.60144 |    354.365553 | Scott Hartman                                                                                                                                                         |
| 436 |     839.15929 |    246.331156 | NA                                                                                                                                                                    |
| 437 |     176.14381 |    194.928636 | Christoph Schomburg                                                                                                                                                   |
| 438 |     487.51946 |    559.230712 | Tasman Dixon                                                                                                                                                          |
| 439 |     212.32565 |    638.217585 | T. Michael Keesey                                                                                                                                                     |
| 440 |     785.95849 |     71.541147 | Smokeybjb                                                                                                                                                             |
| 441 |     453.95801 |    126.342374 | Mathieu Basille                                                                                                                                                       |
| 442 |     816.94036 |    332.921782 | Roberto Díaz Sibaja                                                                                                                                                   |
| 443 |     752.33385 |    631.211777 | Chris huh                                                                                                                                                             |
| 444 |     846.53125 |    456.313942 | CNZdenek                                                                                                                                                              |
| 445 |     202.22928 |    667.834411 | Scott Hartman                                                                                                                                                         |
| 446 |     917.93093 |    571.260415 | Iain Reid                                                                                                                                                             |
| 447 |     225.40406 |    563.207674 | T. Michael Keesey                                                                                                                                                     |
| 448 |     800.96518 |    544.770027 | Scott Hartman                                                                                                                                                         |
| 449 |     448.82940 |    289.522143 | Margot Michaud                                                                                                                                                        |
| 450 |     240.54584 |    357.475220 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 451 |     755.70778 |    570.402637 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 452 |     422.48511 |    114.853502 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 453 |    1007.23068 |    543.293186 | Rene Martin                                                                                                                                                           |
| 454 |     265.72856 |    152.782555 | Maija Karala                                                                                                                                                          |
| 455 |     561.04554 |    332.193658 | Collin Gross                                                                                                                                                          |
| 456 |     685.84378 |     53.319307 | Gareth Monger                                                                                                                                                         |
| 457 |     808.10420 |    466.116109 | T. Michael Keesey                                                                                                                                                     |
| 458 |     716.10463 |    559.495207 | Gareth Monger                                                                                                                                                         |
| 459 |     115.44178 |    502.651471 | Martin R. Smith                                                                                                                                                       |
| 460 |      68.68220 |    273.642626 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                      |
| 461 |     803.65550 |    521.866013 | Collin Gross                                                                                                                                                          |
| 462 |     352.73898 |    293.296874 | Walter Vladimir                                                                                                                                                       |
| 463 |     959.53113 |    368.182347 | Margot Michaud                                                                                                                                                        |
| 464 |      66.28572 |      7.125775 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 465 |     793.05105 |    594.741796 | Carlos Cano-Barbacil                                                                                                                                                  |
| 466 |     354.55507 |    598.351574 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 467 |     445.99952 |    646.448518 | Gareth Monger                                                                                                                                                         |
| 468 |     867.98759 |     22.582397 | NA                                                                                                                                                                    |
| 469 |     767.73128 |     77.499390 | Chris huh                                                                                                                                                             |
| 470 |     304.49658 |    399.657778 | Emily Jane McTavish                                                                                                                                                   |
| 471 |     218.86846 |    362.156087 | Matt Martyniuk                                                                                                                                                        |
| 472 |     771.80129 |    511.204255 | Milton Tan                                                                                                                                                            |
| 473 |     476.82164 |    220.727108 | Zimices                                                                                                                                                               |
| 474 |     637.25118 |    562.386017 | Benjamin Monod-Broca                                                                                                                                                  |
| 475 |     688.02991 |    742.404747 | Scott Hartman                                                                                                                                                         |
| 476 |     494.94804 |    713.893810 | Gareth Monger                                                                                                                                                         |
| 477 |     656.31217 |    393.268508 | T. Michael Keesey                                                                                                                                                     |
| 478 |     994.50708 |     50.137604 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 479 |     108.51846 |    712.122325 | Scott Hartman                                                                                                                                                         |
| 480 |     591.79757 |    473.292398 | Jaime Headden                                                                                                                                                         |
| 481 |     472.06468 |     32.652101 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 482 |     725.08502 |    665.933905 | Dmitry Bogdanov                                                                                                                                                       |
| 483 |     452.46609 |    393.661556 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 484 |     983.58999 |     37.774979 | Matt Crook                                                                                                                                                            |
| 485 |     821.45919 |    737.784417 | Ferran Sayol                                                                                                                                                          |
| 486 |     215.91419 |    469.728456 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 487 |     972.30014 |    377.378709 | Gareth Monger                                                                                                                                                         |
| 488 |     709.98137 |    703.301577 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 489 |     281.27538 |    756.695551 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 490 |     108.60228 |    139.147860 | Chris huh                                                                                                                                                             |
| 491 |     108.48805 |     85.544006 | T. Michael Keesey                                                                                                                                                     |
| 492 |     724.14692 |    694.059412 | Zimices                                                                                                                                                               |
| 493 |     872.65577 |    241.141424 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 494 |     906.70458 |    763.516138 | Andrew A. Farke                                                                                                                                                       |
| 495 |     398.21329 |    222.777109 | Neil Kelley                                                                                                                                                           |
| 496 |     352.97101 |    339.140787 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 497 |     241.76329 |    761.899734 | T. Michael Keesey                                                                                                                                                     |
| 498 |     436.96887 |    785.942225 | Tasman Dixon                                                                                                                                                          |
| 499 |     386.90297 |    362.118941 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 500 |     658.95814 |     49.059943 | Scott Hartman                                                                                                                                                         |
| 501 |     902.79464 |    243.111247 | Jaime Headden                                                                                                                                                         |
| 502 |     354.73113 |    248.168025 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 503 |     820.64426 |    489.945971 | Collin Gross                                                                                                                                                          |
| 504 |     355.12244 |    116.610910 | T. Michael Keesey                                                                                                                                                     |
| 505 |     605.17480 |    136.387902 | Ghedoghedo                                                                                                                                                            |
| 506 |     823.75185 |    372.092164 | Chris huh                                                                                                                                                             |
| 507 |     336.17676 |    701.053033 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 508 |     427.20710 |    684.918661 | T. Michael Keesey                                                                                                                                                     |
| 509 |     389.36825 |    423.000706 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 510 |    1006.75774 |    286.998684 | Mattia Menchetti                                                                                                                                                      |
| 511 |     277.94795 |    392.069345 | T. Michael Keesey                                                                                                                                                     |
| 512 |     891.75594 |    742.297033 | M Kolmann                                                                                                                                                             |
| 513 |     287.26698 |    322.058213 | Gareth Monger                                                                                                                                                         |
| 514 |      55.32300 |    595.456484 | Zimices                                                                                                                                                               |
| 515 |      80.12605 |    640.146598 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 516 |     560.95248 |     76.342403 | Zimices                                                                                                                                                               |
| 517 |     380.40741 |    527.181728 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 518 |     276.10460 |    109.526316 | Margot Michaud                                                                                                                                                        |
| 519 |     320.15966 |    773.577684 | NA                                                                                                                                                                    |
| 520 |      80.08812 |    194.861941 | Tasman Dixon                                                                                                                                                          |
| 521 |     833.70860 |    559.139258 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 522 |     677.57373 |    709.920777 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 523 |     212.94269 |    575.577507 | Neil Kelley                                                                                                                                                           |
| 524 |     301.51316 |    590.875623 | C. Camilo Julián-Caballero                                                                                                                                            |
| 525 |     190.18336 |    230.430750 | Chris huh                                                                                                                                                             |
| 526 |     773.94260 |    610.657645 | Melissa Broussard                                                                                                                                                     |
| 527 |     292.57402 |    251.643523 | Lafage                                                                                                                                                                |
| 528 |    1001.92685 |    476.686349 | Harold N Eyster                                                                                                                                                       |

    #> Your tweet has been posted!
