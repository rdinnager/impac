
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

Matt Crook, T. Michael Keesey, Crystal Maier, Margot Michaud, Felix
Vaux, Gareth Monger, Katie S. Collins, Michael Scroggie, Tasman Dixon,
Birgit Lang, Jack Mayer Wood, xgirouxb, Scott Hartman, Ferran Sayol,
Alexander Schmidt-Lebuhn, zoosnow, Smokeybjb (modified by Mike Keesey),
Zimices, Jagged Fang Designs, Caleb M. Brown, Ignacio Contreras, Yan
Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo),
Matt Martyniuk (vectorized by T. Michael Keesey), Nobu Tamura
(vectorized by T. Michael Keesey), Andrew A. Farke, Lily Hughes, Charles
R. Knight (vectorized by T. Michael Keesey), Sarah Werning, Chuanixn Yu,
Jaime Headden, Maxime Dahirel, Andy Wilson, Chris huh, Christoph
Schomburg, Markus A. Grohme, Maija Karala, Steven Traver, Kent Elson
Sorgon, Noah Schlottman, I. Sáček, Sr. (vectorized by T. Michael
Keesey), Matthew E. Clapham, Ellen Edmonson (illustration) and Timothy
J. Bartley (silhouette), Isaure Scavezzoni, Birgit Szabo, Scott Reid,
Nobu Tamura, vectorized by Zimices, Carlos Cano-Barbacil, Armin Reindl,
M Kolmann, Michelle Site, Yan Wong, Chris A. Hamilton, Harold N Eyster,
Roberto Díaz Sibaja, Liftarn, Kanchi Nanjo, Mattia Menchetti, Gabriela
Palomo-Munoz, Dmitry Bogdanov, Tony Ayling (vectorized by T. Michael
Keesey), Rebecca Groom, Fernando Campos De Domenico, Jake Warner, Jay
Matternes (modified by T. Michael Keesey), Matt Martyniuk (modified by
T. Michael Keesey), Ernst Haeckel (vectorized by T. Michael Keesey),
Matt Celeskey, Myriam\_Ramirez, Becky Barnes, Joanna Wolfe, Renato
Santos, Jonathan Wells, Mr E? (vectorized by T. Michael Keesey),
Verisimilus, Mathew Wedel, Anthony Caravaggi, Falconaumanni and T.
Michael Keesey, Rachel Shoop, Martien Brand (original photo), Renato
Santos (vector silhouette), Michael Day, Dmitry Bogdanov (vectorized by
T. Michael Keesey), Matt Dempsey, DW Bapst, modified from Figure 1 of
Belanger (2011, PALAIOS)., Kosta Mumcuoglu (vectorized by T. Michael
Keesey), Leann Biancani, photo by Kenneth Clifton, Sean McCann, NASA,
Jose Carlos Arenas-Monroy, David Tana, Chloé Schmidt, Scott Hartman
(vectorized by T. Michael Keesey), Darius Nau, L. Shyamal, Robert Bruce
Horsfall (vectorized by T. Michael Keesey), Jimmy Bernot, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Manabu Sakamoto, Lisa Byrne, Ghedoghedo, Stemonitis
(photography) and T. Michael Keesey (vectorization), Smokeybjb, Jaime A.
Headden (vectorized by T. Michael Keesey), Scott Hartman, modified by T.
Michael Keesey, Martin R. Smith, T. Michael Keesey (from a photograph by
Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Martin Kevil,
T. Michael Keesey (vectorization); Yves Bousquet (photography), Steven
Coombs, Nobu Tamura, modified by Andrew A. Farke, Lukasiniho, . Original
drawing by M. Antón, published in Montoya and Morales 1984. Vectorized
by O. Sanisidro, Charles Doolittle Walcott (vectorized by T. Michael
Keesey), (after McCulloch 1908), Jesús Gómez, vectorized by Zimices,
Marmelad, Mathew Stewart, Smokeybjb (vectorized by T. Michael Keesey),
Obsidian Soul (vectorized by T. Michael Keesey), Matt Martyniuk, Manabu
Bessho-Uehara, Robbie N. Cada (vectorized by T. Michael Keesey), Andrew
A. Farke, modified from original by Robert Bruce Horsfall, from Scott
1912, Sharon Wegner-Larsen, Mariana Ruiz Villarreal, Chris Jennings
(Risiatto), Michael B. H. (vectorized by T. Michael Keesey), Gabriel
Lio, vectorized by Zimices, Hans Hillewaert (vectorized by T. Michael
Keesey), Dean Schnabel, T. Michael Keesey (after MPF), Noah Schlottman,
photo by Adam G. Clause, Collin Gross, Neil Kelley, Kailah Thorn & Mark
Hutchinson, Heinrich Harder (vectorized by T. Michael Keesey), Daniel
Jaron, Emily Willoughby, Ricardo Araújo, T. Michael Keesey (after
Ponomarenko), Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.,
Julio Garza, Trond R. Oskars, Smokeybjb, vectorized by Zimices, Alex
Slavenko, Maxwell Lefroy (vectorized by T. Michael Keesey), Andreas
Trepte (vectorized by T. Michael Keesey), Douglas Brown (modified by T.
Michael Keesey), Steven Haddock • Jellywatch.org, Hans Hillewaert
(photo) and T. Michael Keesey (vectorization), Ekaterina Kopeykina
(vectorized by T. Michael Keesey), I. Geoffroy Saint-Hilaire (vectorized
by T. Michael Keesey), Estelle Bourdon, Xavier A. Jenkins, Gabriel
Ugueto, Mike Hanson, Agnello Picorelli, Caio Bernardes, vectorized by
Zimices, Ewald Rübsamen, Apokryltaros (vectorized by T. Michael Keesey),
Mathieu Basille, T. Michael Keesey (from a mount by Allis Markham),
Yusan Yang, Matus Valach, FunkMonk, Tambja (vectorized by T. Michael
Keesey), Philip Chalmers (vectorized by T. Michael Keesey), Jessica Anne
Miller, Kamil S. Jaron, Zachary Quigley, Pete Buchholz, Ingo Braasch,
Oscar Sanisidro, Bryan Carstens, Mathilde Cordellier, Lauren
Sumner-Rooney, Michael P. Taylor, T. Michael Keesey (vectorization) and
Larry Loos (photography), Melissa Broussard, Kai R. Caspar, Eduard Solà
Vázquez, vectorised by Yan Wong, Roger Witter, vectorized by Zimices,
Beth Reinke, Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on
iNaturalist, Amanda Katzer, Sam Droege (photography) and T. Michael
Keesey (vectorization), Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Noah Schlottman,
photo by Casey Dunn, Meliponicultor Itaymbere, ArtFavor & annaleeblysse,
Pranav Iyer (grey ideas), Conty (vectorized by T. Michael Keesey), Cagri
Cevrim, Terpsichores, Alexandre Vong, Servien (vectorized by T. Michael
Keesey), Emma Hughes, Ghedoghedo (vectorized by T. Michael Keesey),
Chase Brownstein, Stanton F. Fink (vectorized by T. Michael Keesey),
Paul O. Lewis, Michele Tobias, Noah Schlottman, photo by Museum of
Geology, University of Tartu, Christian A. Masnaghetti, Lukas Panzarin,
Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey), C.
Camilo Julián-Caballero, Stanton F. Fink, vectorized by Zimices, Emma
Kissling, Erika Schumacher, Cristopher Silva, Matt Wilkins, Abraão
Leite, Tauana J. Cunha, M Hutchinson, Tyler Greenfield, E. R. Waite & H.
M. Hale (vectorized by T. Michael Keesey), Tracy A. Heath, Skye McDavid,
Sergio A. Muñoz-Gómez, Courtney Rockenbach, Cristina Guijarro, CNZdenek,
Xavier Giroux-Bougard, Roberto Diaz Sibaja, based on Domser, Robbie N.
Cada (modified by T. Michael Keesey), Haplochromis (vectorized by T.
Michael Keesey), Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Inessa
Voet, \[unknown\], Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., Evan Swigart
(photography) and T. Michael Keesey (vectorization), terngirl, Thibaut
Brunet, Maky (vectorization), Gabriella Skollar (photography), Rebecca
Lewis (editing), Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall,
T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia
Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika
Timm, and David W. Wrase (photography), Smokeybjb (modified by T.
Michael Keesey), Metalhead64 (vectorized by T. Michael Keesey), Jiekun
He, Yan Wong from drawing in The Century Dictionary (1911), Qiang Ou,
S.Martini, David Orr, Brad McFeeters (vectorized by T. Michael Keesey),
Elisabeth Östman, Mali’o Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Arthur S. Brum, Nobu
Tamura (vectorized by A. Verrière), FunkMonk (Michael B. H.), Karla
Martinez, U.S. National Park Service (vectorized by William Gearty),
Joseph Smit (modified by T. Michael Keesey), Joe Schneid (vectorized by
T. Michael Keesey), RS, Didier Descouens (vectorized by T. Michael
Keesey), Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), Geoff Shaw, Mateus Zica (modified by T. Michael
Keesey), Margret Flinsch, vectorized by Zimices, Robert Gay, modified
from FunkMonk (Michael B.H.) and T. Michael Keesey., B Kimmel, Nobu
Tamura, Tod Robbins, Javier Luque, Baheerathan Murugavel, Jebulon
(vectorized by T. Michael Keesey), NOAA Great Lakes Environmental
Research Laboratory (illustration) and Timothy J. Bartley (silhouette),
Scott Hartman (modified by T. Michael Keesey), Daniel Stadtmauer

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    748.792366 |    217.938069 | Matt Crook                                                                                                                                                                           |
|   2 |    780.266149 |    382.767468 | T. Michael Keesey                                                                                                                                                                    |
|   3 |    207.459992 |    718.959537 | Crystal Maier                                                                                                                                                                        |
|   4 |    621.625024 |    161.182421 | Margot Michaud                                                                                                                                                                       |
|   5 |    813.031085 |    545.367636 | Felix Vaux                                                                                                                                                                           |
|   6 |    821.878236 |    679.284375 | Gareth Monger                                                                                                                                                                        |
|   7 |    338.875284 |    347.220176 | Katie S. Collins                                                                                                                                                                     |
|   8 |    188.455087 |    213.936833 | Michael Scroggie                                                                                                                                                                     |
|   9 |     70.842705 |    404.995714 | Tasman Dixon                                                                                                                                                                         |
|  10 |    415.168523 |    653.910209 | Birgit Lang                                                                                                                                                                          |
|  11 |    639.312805 |    465.234103 | Jack Mayer Wood                                                                                                                                                                      |
|  12 |    822.691146 |    289.533852 | xgirouxb                                                                                                                                                                             |
|  13 |    353.317925 |     74.474382 | Scott Hartman                                                                                                                                                                        |
|  14 |    122.259119 |    632.360836 | Matt Crook                                                                                                                                                                           |
|  15 |    501.697512 |    256.851876 | Ferran Sayol                                                                                                                                                                         |
|  16 |    482.901029 |    373.651210 | Matt Crook                                                                                                                                                                           |
|  17 |    479.307622 |    481.302362 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  18 |     79.006981 |     59.432265 | zoosnow                                                                                                                                                                              |
|  19 |    818.577052 |     56.439476 | Smokeybjb (modified by Mike Keesey)                                                                                                                                                  |
|  20 |    610.663798 |    674.634785 | Zimices                                                                                                                                                                              |
|  21 |    386.267243 |    264.483904 | T. Michael Keesey                                                                                                                                                                    |
|  22 |    908.584414 |    254.226978 | Jack Mayer Wood                                                                                                                                                                      |
|  23 |    238.637463 |    505.876310 | Birgit Lang                                                                                                                                                                          |
|  24 |    710.378406 |    716.764642 | Matt Crook                                                                                                                                                                           |
|  25 |    616.187892 |    557.456155 | Zimices                                                                                                                                                                              |
|  26 |     79.875037 |    467.225035 | Jagged Fang Designs                                                                                                                                                                  |
|  27 |    270.069069 |     47.432429 | Jagged Fang Designs                                                                                                                                                                  |
|  28 |    229.292665 |    119.265685 | Caleb M. Brown                                                                                                                                                                       |
|  29 |    863.342841 |    148.161888 | Matt Crook                                                                                                                                                                           |
|  30 |    673.358846 |     97.437040 | Ignacio Contreras                                                                                                                                                                    |
|  31 |    334.491948 |    501.051297 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                                              |
|  32 |    947.001073 |    671.594447 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
|  33 |    488.433622 |    117.107208 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  34 |    615.786279 |     45.373412 | Andrew A. Farke                                                                                                                                                                      |
|  35 |    958.108636 |     79.679134 | Lily Hughes                                                                                                                                                                          |
|  36 |    898.565779 |    412.301527 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                                  |
|  37 |    358.887508 |    193.298384 | Sarah Werning                                                                                                                                                                        |
|  38 |    238.559813 |    347.457025 | Crystal Maier                                                                                                                                                                        |
|  39 |    931.130128 |    464.266250 | Chuanixn Yu                                                                                                                                                                          |
|  40 |    723.481496 |    375.464035 | Jaime Headden                                                                                                                                                                        |
|  41 |    455.600867 |    186.901133 | Gareth Monger                                                                                                                                                                        |
|  42 |    288.815000 |    616.198331 | Maxime Dahirel                                                                                                                                                                       |
|  43 |    957.993069 |    322.232688 | Andy Wilson                                                                                                                                                                          |
|  44 |    572.157676 |    758.177666 | Chris huh                                                                                                                                                                            |
|  45 |     69.417004 |    173.493877 | Matt Crook                                                                                                                                                                           |
|  46 |    716.867132 |    607.079219 | Christoph Schomburg                                                                                                                                                                  |
|  47 |    116.711381 |    434.810222 | Markus A. Grohme                                                                                                                                                                     |
|  48 |    391.958216 |    115.341777 | Maija Karala                                                                                                                                                                         |
|  49 |     98.063134 |    760.633782 | Steven Traver                                                                                                                                                                        |
|  50 |    633.614220 |    251.963425 | Kent Elson Sorgon                                                                                                                                                                    |
|  51 |    178.721678 |    328.682665 | Gareth Monger                                                                                                                                                                        |
|  52 |    944.530200 |    513.560255 | Noah Schlottman                                                                                                                                                                      |
|  53 |    958.953383 |    765.025034 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                                      |
|  54 |    323.236471 |    750.166239 | Margot Michaud                                                                                                                                                                       |
|  55 |    743.290099 |    146.030591 | Matthew E. Clapham                                                                                                                                                                   |
|  56 |    405.808558 |    586.726331 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
|  57 |    336.216100 |     19.399140 | Maija Karala                                                                                                                                                                         |
|  58 |    920.203550 |    209.792560 | Zimices                                                                                                                                                                              |
|  59 |    158.243473 |    519.949149 | NA                                                                                                                                                                                   |
|  60 |    818.313578 |    766.915516 | Zimices                                                                                                                                                                              |
|  61 |    475.029472 |     40.321706 | Zimices                                                                                                                                                                              |
|  62 |    509.280551 |    721.254185 | Gareth Monger                                                                                                                                                                        |
|  63 |    603.415718 |    408.727669 | Isaure Scavezzoni                                                                                                                                                                    |
|  64 |     98.455309 |    306.225391 | Birgit Szabo                                                                                                                                                                         |
|  65 |    709.645593 |    450.160142 | Scott Reid                                                                                                                                                                           |
|  66 |    258.037581 |    143.542379 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  67 |    958.710373 |    565.686895 | Carlos Cano-Barbacil                                                                                                                                                                 |
|  68 |     62.715510 |    575.391718 | Caleb M. Brown                                                                                                                                                                       |
|  69 |    669.082291 |    300.983763 | Christoph Schomburg                                                                                                                                                                  |
|  70 |    438.894341 |    349.254332 | Matt Crook                                                                                                                                                                           |
|  71 |    434.946498 |    745.888307 | NA                                                                                                                                                                                   |
|  72 |    555.158999 |    631.540819 | Scott Hartman                                                                                                                                                                        |
|  73 |    130.109714 |     92.532143 | Zimices                                                                                                                                                                              |
|  74 |    853.265844 |     35.923668 | Armin Reindl                                                                                                                                                                         |
|  75 |    701.958431 |     72.517312 | Chuanixn Yu                                                                                                                                                                          |
|  76 |    951.123667 |    634.352995 | Zimices                                                                                                                                                                              |
|  77 |   1001.156718 |    400.010820 | Michael Scroggie                                                                                                                                                                     |
|  78 |     29.808516 |    369.531475 | NA                                                                                                                                                                                   |
|  79 |    562.395503 |    721.853655 | Jaime Headden                                                                                                                                                                        |
|  80 |    204.194707 |     69.319083 | Christoph Schomburg                                                                                                                                                                  |
|  81 |    906.773395 |    190.489625 | Zimices                                                                                                                                                                              |
|  82 |    784.500949 |    695.768489 | Markus A. Grohme                                                                                                                                                                     |
|  83 |    291.751163 |    310.634115 | Zimices                                                                                                                                                                              |
|  84 |    877.939502 |    711.576471 | M Kolmann                                                                                                                                                                            |
|  85 |    658.980570 |     50.998742 | Michelle Site                                                                                                                                                                        |
|  86 |    851.574867 |    410.685390 | Yan Wong                                                                                                                                                                             |
|  87 |    100.776631 |    353.440862 | Chris A. Hamilton                                                                                                                                                                    |
|  88 |    867.873849 |    734.825033 | Harold N Eyster                                                                                                                                                                      |
|  89 |    243.482804 |    427.855144 | Christoph Schomburg                                                                                                                                                                  |
|  90 |    942.140002 |    602.961249 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  91 |    936.471413 |    540.199123 | Liftarn                                                                                                                                                                              |
|  92 |    641.950755 |    782.725817 | Kanchi Nanjo                                                                                                                                                                         |
|  93 |     53.089228 |     20.494356 | Mattia Menchetti                                                                                                                                                                     |
|  94 |     85.725026 |    376.506626 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  95 |    341.425300 |    678.543519 | Dmitry Bogdanov                                                                                                                                                                      |
|  96 |    640.888603 |    753.529587 | Christoph Schomburg                                                                                                                                                                  |
|  97 |    159.176463 |    147.596091 | Ferran Sayol                                                                                                                                                                         |
|  98 |    993.490948 |    646.424346 | Birgit Lang                                                                                                                                                                          |
|  99 |    953.890530 |     32.827437 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 100 |    776.539244 |    633.604919 | Zimices                                                                                                                                                                              |
| 101 |    732.158738 |    565.259839 | Matt Crook                                                                                                                                                                           |
| 102 |    763.164645 |    468.082596 | Jagged Fang Designs                                                                                                                                                                  |
| 103 |    893.766388 |    750.144557 | Rebecca Groom                                                                                                                                                                        |
| 104 |    981.920816 |    189.348926 | Matt Crook                                                                                                                                                                           |
| 105 |    119.286763 |    458.534285 | Fernando Campos De Domenico                                                                                                                                                          |
| 106 |   1011.344427 |    176.052720 | Jake Warner                                                                                                                                                                          |
| 107 |    590.691289 |    310.006933 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                                        |
| 108 |    444.820359 |    153.690784 | Steven Traver                                                                                                                                                                        |
| 109 |    493.495092 |    559.522274 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                       |
| 110 |    249.674450 |    763.512385 | Zimices                                                                                                                                                                              |
| 111 |    935.581393 |    167.714365 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 112 |    464.021556 |    364.048172 | Matt Celeskey                                                                                                                                                                        |
| 113 |     99.113713 |    154.100584 | Chuanixn Yu                                                                                                                                                                          |
| 114 |    413.317227 |    424.088643 | Steven Traver                                                                                                                                                                        |
| 115 |    532.707095 |    388.963957 | Myriam\_Ramirez                                                                                                                                                                      |
| 116 |     30.823504 |    496.738360 | Sarah Werning                                                                                                                                                                        |
| 117 |    524.624401 |    514.811630 | Becky Barnes                                                                                                                                                                         |
| 118 |    715.557868 |    411.963981 | Jagged Fang Designs                                                                                                                                                                  |
| 119 |    682.668637 |    221.916552 | Ferran Sayol                                                                                                                                                                         |
| 120 |    759.552411 |    242.300510 | Zimices                                                                                                                                                                              |
| 121 |    423.208702 |    713.065976 | Joanna Wolfe                                                                                                                                                                         |
| 122 |    764.927546 |     91.177955 | Renato Santos                                                                                                                                                                        |
| 123 |    571.531473 |     95.591493 | Matt Crook                                                                                                                                                                           |
| 124 |    977.758344 |    597.803967 | Matt Crook                                                                                                                                                                           |
| 125 |    423.107257 |    571.669911 | NA                                                                                                                                                                                   |
| 126 |    111.553071 |    708.841837 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 127 |    249.451738 |    576.755722 | Zimices                                                                                                                                                                              |
| 128 |    203.275052 |    465.312568 | Jonathan Wells                                                                                                                                                                       |
| 129 |    993.456414 |    131.654366 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 130 |    600.407226 |    617.546368 | NA                                                                                                                                                                                   |
| 131 |    317.312457 |    281.258820 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                                              |
| 132 |     25.059784 |    634.797607 | NA                                                                                                                                                                                   |
| 133 |     83.477526 |    467.309507 | NA                                                                                                                                                                                   |
| 134 |    720.757006 |    395.824586 | Maija Karala                                                                                                                                                                         |
| 135 |    418.481021 |     15.957717 | Verisimilus                                                                                                                                                                          |
| 136 |    567.823557 |    275.106951 | Mathew Wedel                                                                                                                                                                         |
| 137 |    747.299169 |      8.766750 | Anthony Caravaggi                                                                                                                                                                    |
| 138 |    529.395707 |    183.486878 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 139 |    698.802344 |    205.255402 | Joanna Wolfe                                                                                                                                                                         |
| 140 |    315.868985 |    159.551694 | Rebecca Groom                                                                                                                                                                        |
| 141 |    736.503902 |    421.503484 | NA                                                                                                                                                                                   |
| 142 |    598.022600 |    219.610789 | Rachel Shoop                                                                                                                                                                         |
| 143 |    396.428162 |    784.605961 | Margot Michaud                                                                                                                                                                       |
| 144 |    568.239082 |    485.688606 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
| 145 |    231.090737 |    611.709496 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 146 |    381.376927 |    434.705727 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 147 |    426.225985 |    309.823356 | Chris huh                                                                                                                                                                            |
| 148 |    349.300755 |    275.963731 | Michael Day                                                                                                                                                                          |
| 149 |    145.753728 |    540.171100 | Scott Hartman                                                                                                                                                                        |
| 150 |    717.735084 |    779.807942 | Rebecca Groom                                                                                                                                                                        |
| 151 |    846.175427 |    209.791979 | Matt Crook                                                                                                                                                                           |
| 152 |     27.561209 |    160.082380 | Zimices                                                                                                                                                                              |
| 153 |    811.936101 |    332.917924 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 154 |    344.423717 |    233.655705 | Andy Wilson                                                                                                                                                                          |
| 155 |      8.620475 |    206.195672 | Steven Traver                                                                                                                                                                        |
| 156 |    129.084683 |    791.712870 | Zimices                                                                                                                                                                              |
| 157 |     25.046369 |    247.423188 | Matt Dempsey                                                                                                                                                                         |
| 158 |    605.323490 |    382.827675 | Sarah Werning                                                                                                                                                                        |
| 159 |    804.051681 |    728.857423 | Gareth Monger                                                                                                                                                                        |
| 160 |    198.808068 |    482.284621 | Tasman Dixon                                                                                                                                                                         |
| 161 |    483.012007 |    582.889552 | Steven Traver                                                                                                                                                                        |
| 162 |    663.150583 |    784.613130 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                                        |
| 163 |   1012.745843 |    676.221795 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                                    |
| 164 |    440.137470 |    234.434783 | Ferran Sayol                                                                                                                                                                         |
| 165 |    633.669117 |    625.994352 | Jaime Headden                                                                                                                                                                        |
| 166 |   1000.194616 |    425.490315 | Leann Biancani, photo by Kenneth Clifton                                                                                                                                             |
| 167 |    780.570736 |    448.917290 | Matt Crook                                                                                                                                                                           |
| 168 |    143.770553 |    406.742842 | Joanna Wolfe                                                                                                                                                                         |
| 169 |    148.035949 |    728.625155 | Sean McCann                                                                                                                                                                          |
| 170 |    444.498477 |    528.407501 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 171 |    901.686526 |    372.157983 | Michael Scroggie                                                                                                                                                                     |
| 172 |     62.590889 |    597.758269 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 173 |    208.776457 |    544.420653 | Gareth Monger                                                                                                                                                                        |
| 174 |    433.747964 |    373.243031 | NASA                                                                                                                                                                                 |
| 175 |    752.458285 |    634.427079 | Rebecca Groom                                                                                                                                                                        |
| 176 |    508.637590 |    551.970857 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 177 |    913.665738 |    293.914917 | David Tana                                                                                                                                                                           |
| 178 |    198.851312 |    493.659349 | Chloé Schmidt                                                                                                                                                                        |
| 179 |    211.794750 |    640.611209 | Chris huh                                                                                                                                                                            |
| 180 |    475.703749 |    790.773085 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                                      |
| 181 |    870.134147 |    358.476307 | Darius Nau                                                                                                                                                                           |
| 182 |    688.527745 |    473.926296 | T. Michael Keesey                                                                                                                                                                    |
| 183 |     65.739047 |    226.987471 | Steven Traver                                                                                                                                                                        |
| 184 |    597.850278 |     90.633009 | L. Shyamal                                                                                                                                                                           |
| 185 |    172.232564 |    533.653549 | Gareth Monger                                                                                                                                                                        |
| 186 |    937.892849 |    190.201054 | Zimices                                                                                                                                                                              |
| 187 |    204.043673 |    503.723666 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                              |
| 188 |    350.365251 |    400.705633 | Christoph Schomburg                                                                                                                                                                  |
| 189 |     15.274872 |    240.773032 | Rebecca Groom                                                                                                                                                                        |
| 190 |    931.835093 |    260.902418 | Margot Michaud                                                                                                                                                                       |
| 191 |    875.744168 |     45.181807 | Jaime Headden                                                                                                                                                                        |
| 192 |    695.935446 |     49.512790 | Jimmy Bernot                                                                                                                                                                         |
| 193 |      8.384172 |    652.057045 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 194 |    911.256547 |    224.545671 | Manabu Sakamoto                                                                                                                                                                      |
| 195 |    172.299844 |    697.141675 | NA                                                                                                                                                                                   |
| 196 |    954.045979 |    616.620399 | Lisa Byrne                                                                                                                                                                           |
| 197 |    310.451837 |    421.943115 | Matt Crook                                                                                                                                                                           |
| 198 |    153.992137 |     60.495507 | Zimices                                                                                                                                                                              |
| 199 |    105.860608 |    729.150143 | Ghedoghedo                                                                                                                                                                           |
| 200 |     23.819596 |    273.566741 | Matt Crook                                                                                                                                                                           |
| 201 |     11.647008 |    105.438625 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 202 |    720.816339 |    785.401933 | Smokeybjb                                                                                                                                                                            |
| 203 |    292.094341 |    688.303527 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                                   |
| 204 |    145.346078 |    496.310076 | Scott Hartman                                                                                                                                                                        |
| 205 |    102.656323 |    540.434877 | NA                                                                                                                                                                                   |
| 206 |    778.743880 |    441.123847 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
| 207 |    394.153782 |    170.612039 | Armin Reindl                                                                                                                                                                         |
| 208 |    580.111315 |    789.719177 | Martin R. Smith                                                                                                                                                                      |
| 209 |    826.745029 |    356.833927 | Yan Wong                                                                                                                                                                             |
| 210 |    568.150470 |    167.674846 | Scott Hartman                                                                                                                                                                        |
| 211 |    452.012915 |    325.377504 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                                    |
| 212 |    694.268443 |    231.500613 | Jagged Fang Designs                                                                                                                                                                  |
| 213 |    278.004332 |    695.790419 | Matt Crook                                                                                                                                                                           |
| 214 |    199.328622 |    277.791332 | Birgit Lang                                                                                                                                                                          |
| 215 |    535.121794 |    251.433622 | Martin Kevil                                                                                                                                                                         |
| 216 |    264.665327 |    714.290381 | Matt Crook                                                                                                                                                                           |
| 217 |     55.086691 |    202.229129 | Jagged Fang Designs                                                                                                                                                                  |
| 218 |     25.149760 |    742.785846 | Matt Crook                                                                                                                                                                           |
| 219 |    720.429763 |    522.243195 | Gareth Monger                                                                                                                                                                        |
| 220 |    851.317654 |    450.598119 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                                       |
| 221 |    479.991695 |    633.372902 | Matt Crook                                                                                                                                                                           |
| 222 |    988.846796 |    357.388983 | Michelle Site                                                                                                                                                                        |
| 223 |    891.951395 |    353.400537 | Steven Coombs                                                                                                                                                                        |
| 224 |   1002.201160 |    599.392301 | Zimices                                                                                                                                                                              |
| 225 |    417.960918 |    610.202405 | Chris huh                                                                                                                                                                            |
| 226 |    650.331615 |    797.245261 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
| 227 |    890.877630 |    779.644682 | Lukasiniho                                                                                                                                                                           |
| 228 |    518.160608 |    299.508672 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                                    |
| 229 |      5.168338 |    373.612942 | NA                                                                                                                                                                                   |
| 230 |    870.551542 |    479.218820 | Scott Reid                                                                                                                                                                           |
| 231 |    423.535765 |    546.287498 | Jagged Fang Designs                                                                                                                                                                  |
| 232 |    418.536606 |    497.011312 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 233 |    962.849045 |    160.370682 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                                          |
| 234 |    296.781613 |    435.528046 | Ignacio Contreras                                                                                                                                                                    |
| 235 |    935.053798 |    786.956672 | Zimices                                                                                                                                                                              |
| 236 |    720.700771 |    203.363918 | Scott Hartman                                                                                                                                                                        |
| 237 |    908.399078 |    597.736453 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 238 |    173.085983 |    131.125115 | Margot Michaud                                                                                                                                                                       |
| 239 |    246.218965 |    740.284086 | Matt Crook                                                                                                                                                                           |
| 240 |     86.250346 |    730.138149 | Matthew E. Clapham                                                                                                                                                                   |
| 241 |    855.728852 |     88.004361 | Gareth Monger                                                                                                                                                                        |
| 242 |    422.148172 |    791.330360 | (after McCulloch 1908)                                                                                                                                                               |
| 243 |    674.006758 |      4.591184 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 244 |    987.312706 |    122.174592 | Marmelad                                                                                                                                                                             |
| 245 |    547.575428 |    518.187071 | Mathew Stewart                                                                                                                                                                       |
| 246 |   1001.759872 |    240.248931 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 247 |    173.734392 |     92.320458 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 248 |    672.728027 |    132.090931 | Rachel Shoop                                                                                                                                                                         |
| 249 |    681.583508 |    370.681179 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 250 |    298.274617 |    149.922200 | Andy Wilson                                                                                                                                                                          |
| 251 |    245.348334 |    788.264799 | Katie S. Collins                                                                                                                                                                     |
| 252 |   1009.411902 |    721.315355 | Jagged Fang Designs                                                                                                                                                                  |
| 253 |    184.946447 |    510.684262 | Dmitry Bogdanov                                                                                                                                                                      |
| 254 |    354.949282 |    140.933437 | Matt Crook                                                                                                                                                                           |
| 255 |    409.321147 |    556.009320 | Maija Karala                                                                                                                                                                         |
| 256 |    556.802605 |      8.752996 | Margot Michaud                                                                                                                                                                       |
| 257 |    839.309945 |     16.156638 | Matt Martyniuk                                                                                                                                                                       |
| 258 |    690.509621 |    625.997759 | Tasman Dixon                                                                                                                                                                         |
| 259 |    254.223382 |    668.788239 | Gareth Monger                                                                                                                                                                        |
| 260 |    754.421435 |    481.349875 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 261 |    691.934687 |     64.566083 | Jimmy Bernot                                                                                                                                                                         |
| 262 |    498.369349 |    782.157057 | Jagged Fang Designs                                                                                                                                                                  |
| 263 |    816.321279 |    420.960478 | T. Michael Keesey                                                                                                                                                                    |
| 264 |    733.279836 |     27.766734 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 265 |    524.461696 |    490.432257 | Steven Traver                                                                                                                                                                        |
| 266 |    412.444088 |    215.900573 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                                    |
| 267 |     65.777520 |    258.806954 | Ignacio Contreras                                                                                                                                                                    |
| 268 |    785.303155 |    658.596764 | Margot Michaud                                                                                                                                                                       |
| 269 |     21.783861 |    332.552986 | NA                                                                                                                                                                                   |
| 270 |    963.968753 |    128.873174 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 271 |     38.541652 |    130.489220 | NA                                                                                                                                                                                   |
| 272 |    679.033808 |    200.098330 | Harold N Eyster                                                                                                                                                                      |
| 273 |    989.157951 |    627.984783 | Mariana Ruiz Villarreal                                                                                                                                                              |
| 274 |    550.861968 |    427.919343 | Matt Crook                                                                                                                                                                           |
| 275 |    175.518304 |    686.398824 | Chris Jennings (Risiatto)                                                                                                                                                            |
| 276 |    904.190781 |    698.392957 | Chris huh                                                                                                                                                                            |
| 277 |    914.055423 |    487.260384 | Margot Michaud                                                                                                                                                                       |
| 278 |    168.357211 |    410.234050 | Ferran Sayol                                                                                                                                                                         |
| 279 |    509.262029 |    129.964493 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 280 |    382.121875 |    714.656051 | Margot Michaud                                                                                                                                                                       |
| 281 |    824.342877 |     93.516965 | Anthony Caravaggi                                                                                                                                                                    |
| 282 |    152.928785 |    675.436597 | NA                                                                                                                                                                                   |
| 283 |    787.200395 |    645.144848 | Gabriel Lio, vectorized by Zimices                                                                                                                                                   |
| 284 |    309.937445 |    245.536249 | Margot Michaud                                                                                                                                                                       |
| 285 |    834.332439 |    650.360743 | Matt Crook                                                                                                                                                                           |
| 286 |    550.840914 |    485.012209 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 287 |    933.631972 |     11.651796 | Dean Schnabel                                                                                                                                                                        |
| 288 |    324.966589 |    445.555657 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 289 |    525.774743 |    790.624903 | Gareth Monger                                                                                                                                                                        |
| 290 |    486.415827 |    209.549805 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 291 |    550.431518 |     72.456125 | Noah Schlottman, photo by Adam G. Clause                                                                                                                                             |
| 292 |     21.488449 |     54.472768 | Collin Gross                                                                                                                                                                         |
| 293 |    172.257876 |    502.644828 | Neil Kelley                                                                                                                                                                          |
| 294 |    745.984263 |    615.943056 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 295 |    727.091150 |     84.381010 | Margot Michaud                                                                                                                                                                       |
| 296 |     49.628645 |    608.681377 | Gareth Monger                                                                                                                                                                        |
| 297 |    295.710976 |     16.099652 | Scott Hartman                                                                                                                                                                        |
| 298 |    146.843383 |    146.585370 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 299 |    980.823315 |     10.932232 | Ferran Sayol                                                                                                                                                                         |
| 300 |    891.951346 |     20.026817 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                                    |
| 301 |    972.512591 |    544.079559 | Rebecca Groom                                                                                                                                                                        |
| 302 |    190.425624 |    143.760328 | Dean Schnabel                                                                                                                                                                        |
| 303 |    152.581504 |    276.773292 | Steven Traver                                                                                                                                                                        |
| 304 |    833.143944 |    234.507248 | Matt Dempsey                                                                                                                                                                         |
| 305 |    381.634536 |    309.530725 | Daniel Jaron                                                                                                                                                                         |
| 306 |    298.727735 |    159.547369 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 307 |    996.211066 |    447.095574 | Margot Michaud                                                                                                                                                                       |
| 308 |    540.376686 |    258.473128 | Andrew A. Farke                                                                                                                                                                      |
| 309 |    568.719916 |    179.838824 | Matt Crook                                                                                                                                                                           |
| 310 |    866.534516 |      7.784345 | Emily Willoughby                                                                                                                                                                     |
| 311 |    803.499023 |    227.048872 | Ricardo Araújo                                                                                                                                                                       |
| 312 |    559.915586 |    454.600278 | T. Michael Keesey (after Ponomarenko)                                                                                                                                                |
| 313 |    992.391251 |    391.193000 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 314 |    689.317361 |    773.784305 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 315 |     57.107859 |    319.404653 | Margot Michaud                                                                                                                                                                       |
| 316 |    568.686021 |    207.615781 | Andy Wilson                                                                                                                                                                          |
| 317 |    599.461642 |     81.392205 | T. Michael Keesey                                                                                                                                                                    |
| 318 |    846.382477 |      7.631384 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                                |
| 319 |    935.280870 |    281.033615 | Zimices                                                                                                                                                                              |
| 320 |     36.966858 |     46.237999 | Jake Warner                                                                                                                                                                          |
| 321 |     50.783902 |    529.460817 | Julio Garza                                                                                                                                                                          |
| 322 |    661.335776 |    477.044470 | Steven Traver                                                                                                                                                                        |
| 323 |    180.572806 |    492.461336 | Trond R. Oskars                                                                                                                                                                      |
| 324 |    266.580777 |    781.487806 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
| 325 |     47.838712 |    338.869805 | Andy Wilson                                                                                                                                                                          |
| 326 |    972.180778 |    744.504761 | NA                                                                                                                                                                                   |
| 327 |   1011.758074 |    443.018134 | Alex Slavenko                                                                                                                                                                        |
| 328 |    389.442709 |    558.559518 | Sarah Werning                                                                                                                                                                        |
| 329 |    357.839267 |    416.351873 | Margot Michaud                                                                                                                                                                       |
| 330 |    294.948577 |    384.862322 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 331 |    347.955864 |    637.367924 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 332 |    757.837954 |    607.181363 | Jagged Fang Designs                                                                                                                                                                  |
| 333 |     36.090075 |    615.476417 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                     |
| 334 |     12.416980 |    250.543571 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                        |
| 335 |    999.525024 |    703.411266 | Jagged Fang Designs                                                                                                                                                                  |
| 336 |    628.336203 |    395.781786 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 337 |    131.319235 |      2.523328 | Markus A. Grohme                                                                                                                                                                     |
| 338 |    520.416943 |    192.541436 | Felix Vaux                                                                                                                                                                           |
| 339 |    279.890930 |    276.617837 | Scott Hartman                                                                                                                                                                        |
| 340 |    943.905593 |    492.086844 | Margot Michaud                                                                                                                                                                       |
| 341 |    475.781948 |     15.151630 | Jagged Fang Designs                                                                                                                                                                  |
| 342 |    559.205536 |    218.396048 | Zimices                                                                                                                                                                              |
| 343 |    926.960329 |    369.140106 | Margot Michaud                                                                                                                                                                       |
| 344 |    427.587464 |    327.471442 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 345 |     23.804401 |    262.134432 | Margot Michaud                                                                                                                                                                       |
| 346 |    998.944626 |    483.048226 | Gareth Monger                                                                                                                                                                        |
| 347 |    398.732297 |    225.023604 | Collin Gross                                                                                                                                                                         |
| 348 |    437.837461 |    390.945282 | Jagged Fang Designs                                                                                                                                                                  |
| 349 |    330.083855 |    152.751937 | Steven Traver                                                                                                                                                                        |
| 350 |    895.209230 |    201.328101 | NA                                                                                                                                                                                   |
| 351 |    154.944314 |     79.932913 | NA                                                                                                                                                                                   |
| 352 |    790.730953 |    708.706514 | T. Michael Keesey                                                                                                                                                                    |
| 353 |    150.158316 |     46.115444 | Yan Wong                                                                                                                                                                             |
| 354 |     85.535545 |     42.006824 | Maxime Dahirel                                                                                                                                                                       |
| 355 |    682.539879 |     57.801792 | M Kolmann                                                                                                                                                                            |
| 356 |    719.208760 |    745.717715 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 357 |    201.430444 |    439.264380 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 358 |    967.499701 |      7.827925 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                                |
| 359 |     44.375846 |    601.643946 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                          |
| 360 |    391.821316 |    418.090747 | Alex Slavenko                                                                                                                                                                        |
| 361 |    946.574460 |    416.437271 | Andy Wilson                                                                                                                                                                          |
| 362 |    445.003077 |     16.344001 | Tasman Dixon                                                                                                                                                                         |
| 363 |    239.990192 |    586.256350 | Ignacio Contreras                                                                                                                                                                    |
| 364 |    472.242916 |    728.491897 | Estelle Bourdon                                                                                                                                                                      |
| 365 |    593.514881 |    775.810684 | Andy Wilson                                                                                                                                                                          |
| 366 |    176.395917 |    407.845600 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                                    |
| 367 |    401.577830 |     66.214262 | Mike Hanson                                                                                                                                                                          |
| 368 |    992.449928 |    754.009827 | Matt Martyniuk                                                                                                                                                                       |
| 369 |    983.600887 |    421.048252 | Birgit Lang                                                                                                                                                                          |
| 370 |    793.011183 |    106.299149 | Sarah Werning                                                                                                                                                                        |
| 371 |    182.601258 |     29.068920 | Margot Michaud                                                                                                                                                                       |
| 372 |     20.954372 |    297.766208 | Margot Michaud                                                                                                                                                                       |
| 373 |    354.466610 |    688.985875 | Agnello Picorelli                                                                                                                                                                    |
| 374 |    737.338679 |    600.328153 | Caio Bernardes, vectorized by Zimices                                                                                                                                                |
| 375 |    292.868294 |    423.670606 | Matt Crook                                                                                                                                                                           |
| 376 |    247.208582 |    599.729473 | Ewald Rübsamen                                                                                                                                                                       |
| 377 |    913.428590 |    304.737825 | T. Michael Keesey                                                                                                                                                                    |
| 378 |    970.321739 |    144.719020 | Margot Michaud                                                                                                                                                                       |
| 379 |    913.998861 |      7.094019 | Markus A. Grohme                                                                                                                                                                     |
| 380 |    744.857181 |    315.777458 | Joanna Wolfe                                                                                                                                                                         |
| 381 |    441.950801 |    559.363558 | NA                                                                                                                                                                                   |
| 382 |    208.038658 |    417.857279 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 383 |    748.797290 |    542.168569 | Mathieu Basille                                                                                                                                                                      |
| 384 |     41.159924 |    298.434598 | Matt Martyniuk                                                                                                                                                                       |
| 385 |     24.849735 |    541.740758 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                                    |
| 386 |     91.783616 |     94.298057 | Becky Barnes                                                                                                                                                                         |
| 387 |      8.192629 |    153.422653 | Scott Hartman                                                                                                                                                                        |
| 388 |    166.466398 |     15.671780 | Gareth Monger                                                                                                                                                                        |
| 389 |    340.533233 |    289.796056 | Zimices                                                                                                                                                                              |
| 390 |    389.495471 |    157.493572 | Scott Hartman                                                                                                                                                                        |
| 391 |    515.223396 |    414.873031 | Steven Traver                                                                                                                                                                        |
| 392 |    587.940545 |    644.363373 | Yusan Yang                                                                                                                                                                           |
| 393 |    812.530134 |    200.182822 | Maija Karala                                                                                                                                                                         |
| 394 |     47.540120 |    105.577023 | Lukasiniho                                                                                                                                                                           |
| 395 |    467.524194 |    601.156603 | Matus Valach                                                                                                                                                                         |
| 396 |    676.567790 |    784.899079 | Margot Michaud                                                                                                                                                                       |
| 397 |    991.483764 |    156.273552 | FunkMonk                                                                                                                                                                             |
| 398 |     93.503193 |    113.170711 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                             |
| 399 |   1011.181320 |    132.336855 | Margot Michaud                                                                                                                                                                       |
| 400 |    149.490494 |     14.287277 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
| 401 |    540.841815 |    383.051072 | NA                                                                                                                                                                                   |
| 402 |    323.689462 |    298.523852 | Tasman Dixon                                                                                                                                                                         |
| 403 |    316.432114 |    688.282075 | Margot Michaud                                                                                                                                                                       |
| 404 |   1014.342257 |    538.961854 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 405 |    994.601371 |     96.243418 | Matt Crook                                                                                                                                                                           |
| 406 |    363.243569 |    156.219269 | Jessica Anne Miller                                                                                                                                                                  |
| 407 |    705.656148 |     38.279880 | Jagged Fang Designs                                                                                                                                                                  |
| 408 |    854.202330 |    693.299812 | Kamil S. Jaron                                                                                                                                                                       |
| 409 |    328.880373 |    645.461015 | Gareth Monger                                                                                                                                                                        |
| 410 |    396.975251 |    456.321209 | Margot Michaud                                                                                                                                                                       |
| 411 |    710.554061 |    648.112555 | Jagged Fang Designs                                                                                                                                                                  |
| 412 |    721.082339 |    382.912526 | Zachary Quigley                                                                                                                                                                      |
| 413 |    633.914242 |    638.000322 | T. Michael Keesey                                                                                                                                                                    |
| 414 |    895.583979 |    619.671480 | Zimices                                                                                                                                                                              |
| 415 |     23.208587 |    470.715528 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 416 |    749.755915 |    330.860473 | NA                                                                                                                                                                                   |
| 417 |    668.324883 |    321.757033 | Pete Buchholz                                                                                                                                                                        |
| 418 |    176.526996 |    448.527434 | Felix Vaux                                                                                                                                                                           |
| 419 |    797.112868 |    659.112356 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 420 |    897.922056 |    648.797986 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 421 |     61.114673 |    247.453781 | Ingo Braasch                                                                                                                                                                         |
| 422 |    519.587303 |    173.234411 | Dean Schnabel                                                                                                                                                                        |
| 423 |     90.394290 |     26.859341 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 424 |    714.452198 |    559.130768 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 425 |    613.919649 |    497.262323 | Oscar Sanisidro                                                                                                                                                                      |
| 426 |    792.256668 |    226.127470 | Bryan Carstens                                                                                                                                                                       |
| 427 |    651.513178 |     77.209489 | Zimices                                                                                                                                                                              |
| 428 |    975.314547 |    632.675264 | NA                                                                                                                                                                                   |
| 429 |    658.001048 |    214.929823 | Chris huh                                                                                                                                                                            |
| 430 |    898.670795 |    539.473477 | Matt Crook                                                                                                                                                                           |
| 431 |    633.706575 |    431.746416 | Mathilde Cordellier                                                                                                                                                                  |
| 432 |    626.547180 |    408.021637 | Anthony Caravaggi                                                                                                                                                                    |
| 433 |    827.932591 |    728.896533 | Matt Crook                                                                                                                                                                           |
| 434 |     46.415960 |    165.344432 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 435 |    588.810852 |    286.372195 | Michael P. Taylor                                                                                                                                                                    |
| 436 |    588.266525 |    490.532411 | Katie S. Collins                                                                                                                                                                     |
| 437 |    278.134268 |     70.877236 | NA                                                                                                                                                                                   |
| 438 |    417.002358 |    229.409130 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                                       |
| 439 |    721.031793 |    542.797804 | Zimices                                                                                                                                                                              |
| 440 |    395.851188 |     94.459603 | Gareth Monger                                                                                                                                                                        |
| 441 |    896.531302 |    319.630649 | NA                                                                                                                                                                                   |
| 442 |    683.996014 |    460.901034 | Melissa Broussard                                                                                                                                                                    |
| 443 |    330.198045 |    612.101367 | NA                                                                                                                                                                                   |
| 444 |    320.547866 |    403.110462 | T. Michael Keesey                                                                                                                                                                    |
| 445 |   1003.336999 |    313.665202 | Melissa Broussard                                                                                                                                                                    |
| 446 |    648.791395 |    591.116872 | Andy Wilson                                                                                                                                                                          |
| 447 |     81.922354 |    531.964555 | Kai R. Caspar                                                                                                                                                                        |
| 448 |    285.236526 |     12.223140 | T. Michael Keesey                                                                                                                                                                    |
| 449 |    741.982630 |    298.090662 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                                          |
| 450 |   1012.070933 |    267.043815 | Roger Witter, vectorized by Zimices                                                                                                                                                  |
| 451 |    802.014710 |     27.357993 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                                    |
| 452 |    336.987018 |    431.518298 | FunkMonk                                                                                                                                                                             |
| 453 |    563.118658 |    591.489255 | Dean Schnabel                                                                                                                                                                        |
| 454 |    734.155301 |    483.764331 | Becky Barnes                                                                                                                                                                         |
| 455 |    614.281955 |    376.825986 | NA                                                                                                                                                                                   |
| 456 |    960.234852 |    492.900835 | Zimices                                                                                                                                                                              |
| 457 |    723.183679 |    475.492837 | Beth Reinke                                                                                                                                                                          |
| 458 |    898.775150 |    295.323559 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                                |
| 459 |    699.449721 |     11.396554 | Michael Scroggie                                                                                                                                                                     |
| 460 |    153.333993 |    511.888451 | T. Michael Keesey                                                                                                                                                                    |
| 461 |    554.176672 |    388.415073 | Amanda Katzer                                                                                                                                                                        |
| 462 |    955.581035 |    121.484486 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 463 |    171.655240 |    479.798559 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 464 |    953.056808 |    170.417767 | Margot Michaud                                                                                                                                                                       |
| 465 |    575.364670 |    442.071313 | Zimices                                                                                                                                                                              |
| 466 |    978.182008 |    168.279255 | Beth Reinke                                                                                                                                                                          |
| 467 |    569.413996 |    383.689050 | Zimices                                                                                                                                                                              |
| 468 |    681.115151 |    281.746700 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 469 |     64.721761 |    373.839324 | Armin Reindl                                                                                                                                                                         |
| 470 |    751.117420 |    303.442459 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 471 |    439.214483 |    380.200166 | Ferran Sayol                                                                                                                                                                         |
| 472 |     50.477935 |    357.021798 | Birgit Lang                                                                                                                                                                          |
| 473 |     11.011890 |    420.678410 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 474 |    802.274429 |     96.324881 | Matt Crook                                                                                                                                                                           |
| 475 |    118.354877 |    415.941294 | Yan Wong                                                                                                                                                                             |
| 476 |    280.212474 |    529.303471 | Scott Hartman                                                                                                                                                                        |
| 477 |     58.466237 |     42.886131 | Margot Michaud                                                                                                                                                                       |
| 478 |     71.549458 |     43.222358 | NA                                                                                                                                                                                   |
| 479 |   1011.217298 |    772.415918 | Steven Traver                                                                                                                                                                        |
| 480 |    252.155618 |     17.190784 | Emily Willoughby                                                                                                                                                                     |
| 481 |    667.382664 |    407.432960 | Melissa Broussard                                                                                                                                                                    |
| 482 |    746.973577 |    205.137414 | Sarah Werning                                                                                                                                                                        |
| 483 |     71.273481 |    181.735993 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 484 |    192.803459 |    411.090431 | Michelle Site                                                                                                                                                                        |
| 485 |    884.151543 |    382.782589 | Ignacio Contreras                                                                                                                                                                    |
| 486 |    274.005885 |    413.205925 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 487 |    244.616642 |    553.908518 | Matt Crook                                                                                                                                                                           |
| 488 |    630.599185 |    483.958448 | Zimices                                                                                                                                                                              |
| 489 |    122.745182 |    544.732320 | Margot Michaud                                                                                                                                                                       |
| 490 |    590.455821 |    609.454800 | T. Michael Keesey                                                                                                                                                                    |
| 491 |    344.213980 |    791.916598 | Trond R. Oskars                                                                                                                                                                      |
| 492 |    424.886483 |    138.949856 | Michael Day                                                                                                                                                                          |
| 493 |    201.555300 |    779.455946 | Chris huh                                                                                                                                                                            |
| 494 |    557.570775 |    248.309250 | Jagged Fang Designs                                                                                                                                                                  |
| 495 |    147.488323 |    374.549587 | Crystal Maier                                                                                                                                                                        |
| 496 |    895.725028 |    430.654501 | Zimices                                                                                                                                                                              |
| 497 |    603.140364 |    478.642547 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 498 |    279.878537 |    550.009908 | Tasman Dixon                                                                                                                                                                         |
| 499 |    242.267178 |    626.038164 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 500 |    384.064619 |    145.641415 | Jonathan Wells                                                                                                                                                                       |
| 501 |    300.266221 |    282.941929 | Andy Wilson                                                                                                                                                                          |
| 502 |    568.588664 |    636.513100 | Crystal Maier                                                                                                                                                                        |
| 503 |    850.318998 |    318.340821 | Chris huh                                                                                                                                                                            |
| 504 |    493.112292 |    151.618070 | Chris huh                                                                                                                                                                            |
| 505 |    203.050231 |    430.022879 | Meliponicultor Itaymbere                                                                                                                                                             |
| 506 |    288.145361 |     57.847365 | Smokeybjb                                                                                                                                                                            |
| 507 |    100.339100 |    132.821062 | ArtFavor & annaleeblysse                                                                                                                                                             |
| 508 |   1005.672857 |    289.137481 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 509 |    674.178437 |    553.173968 | Tasman Dixon                                                                                                                                                                         |
| 510 |    731.236633 |    702.499052 | Steven Traver                                                                                                                                                                        |
| 511 |     35.041991 |    231.456368 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
| 512 |    227.850014 |    406.880041 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 513 |    541.688321 |    612.763852 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 514 |    885.846465 |    763.701249 | Margot Michaud                                                                                                                                                                       |
| 515 |    462.808132 |    554.694435 | Martin Kevil                                                                                                                                                                         |
| 516 |    128.677646 |    391.042245 | Maija Karala                                                                                                                                                                         |
| 517 |    853.657915 |    328.714727 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 518 |    374.060562 |    404.274333 | Katie S. Collins                                                                                                                                                                     |
| 519 |    684.455579 |    266.074265 | Scott Hartman                                                                                                                                                                        |
| 520 |    894.822806 |    109.085519 | NA                                                                                                                                                                                   |
| 521 |    158.389569 |    117.887623 | NA                                                                                                                                                                                   |
| 522 |    402.061169 |    488.284425 | Cagri Cevrim                                                                                                                                                                         |
| 523 |    345.772816 |    158.559316 | Matt Crook                                                                                                                                                                           |
| 524 |     24.593665 |    759.074485 | Matt Martyniuk                                                                                                                                                                       |
| 525 |     23.531625 |    122.619735 | Tasman Dixon                                                                                                                                                                         |
| 526 |    137.159699 |    715.772925 | Terpsichores                                                                                                                                                                         |
| 527 |    872.076057 |    656.072845 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 528 |     99.067351 |    586.385109 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 529 |     19.557216 |    590.543734 | Zimices                                                                                                                                                                              |
| 530 |    364.024125 |    598.812098 | Margot Michaud                                                                                                                                                                       |
| 531 |     77.516456 |    191.859812 | Andy Wilson                                                                                                                                                                          |
| 532 |    535.196452 |    775.611185 | Scott Hartman                                                                                                                                                                        |
| 533 |    824.461807 |    221.950252 | Matt Crook                                                                                                                                                                           |
| 534 |    851.466022 |     71.694507 | Alexandre Vong                                                                                                                                                                       |
| 535 |    418.437873 |    152.541975 | Servien (vectorized by T. Michael Keesey)                                                                                                                                            |
| 536 |    144.108467 |    455.262235 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 537 |    861.284743 |    643.417911 | Emma Hughes                                                                                                                                                                          |
| 538 |     19.525447 |    706.530421 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 539 |   1000.698739 |    339.563315 | Andy Wilson                                                                                                                                                                          |
| 540 |    408.090738 |    342.368391 | Chase Brownstein                                                                                                                                                                     |
| 541 |    574.129689 |     11.133073 | Joanna Wolfe                                                                                                                                                                         |
| 542 |    299.334713 |    713.780816 | Ingo Braasch                                                                                                                                                                         |
| 543 |    449.225283 |    776.967161 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 544 |    484.084175 |    171.903620 | Markus A. Grohme                                                                                                                                                                     |
| 545 |    178.565575 |    781.818291 | Alex Slavenko                                                                                                                                                                        |
| 546 |     20.166377 |    164.818996 | Scott Hartman                                                                                                                                                                        |
| 547 |    420.886883 |    399.876904 | Pete Buchholz                                                                                                                                                                        |
| 548 |    192.760040 |    652.417912 | Matt Crook                                                                                                                                                                           |
| 549 |    519.286733 |    392.675213 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 550 |    527.909917 |    531.556555 | Paul O. Lewis                                                                                                                                                                        |
| 551 |   1000.393815 |    542.481774 | Rebecca Groom                                                                                                                                                                        |
| 552 |    714.505937 |    731.547444 | Tasman Dixon                                                                                                                                                                         |
| 553 |    337.602431 |    419.492542 | Michele Tobias                                                                                                                                                                       |
| 554 |    648.087403 |    696.484361 | Matt Crook                                                                                                                                                                           |
| 555 |   1008.110440 |    484.374090 | Maija Karala                                                                                                                                                                         |
| 556 |    445.745868 |      8.034285 | Matt Crook                                                                                                                                                                           |
| 557 |    224.804266 |     71.514225 | Margot Michaud                                                                                                                                                                       |
| 558 |    103.885754 |    468.861487 | Steven Traver                                                                                                                                                                        |
| 559 |    636.902008 |    732.320306 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                     |
| 560 |    575.859598 |    744.129670 | Christian A. Masnaghetti                                                                                                                                                             |
| 561 |   1003.310776 |    372.859287 | Ferran Sayol                                                                                                                                                                         |
| 562 |    616.432814 |    769.148731 | Lukas Panzarin                                                                                                                                                                       |
| 563 |     72.641968 |    552.434743 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                                      |
| 564 |    334.684234 |    716.269039 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 565 |    816.135391 |     12.402044 | Stanton F. Fink, vectorized by Zimices                                                                                                                                               |
| 566 |    277.193145 |    795.302160 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 567 |    877.656657 |    604.212338 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 568 |    505.952218 |    490.769682 | Matt Crook                                                                                                                                                                           |
| 569 |    103.161697 |     39.304779 | Steven Traver                                                                                                                                                                        |
| 570 |    445.485238 |    722.386082 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 571 |    848.147088 |    664.591462 | ArtFavor & annaleeblysse                                                                                                                                                             |
| 572 |    220.577307 |     12.306802 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 573 |    839.727535 |    793.858861 | Zimices                                                                                                                                                                              |
| 574 |    963.220608 |    254.725308 | T. Michael Keesey                                                                                                                                                                    |
| 575 |     19.413580 |    288.741888 | Emma Kissling                                                                                                                                                                        |
| 576 |    958.977160 |    275.697188 | Erika Schumacher                                                                                                                                                                     |
| 577 |    201.498456 |    136.510849 | Steven Traver                                                                                                                                                                        |
| 578 |     11.711642 |    505.893247 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 579 |    657.540300 |    185.011030 | Scott Hartman                                                                                                                                                                        |
| 580 |    435.740494 |    783.145887 | Cristopher Silva                                                                                                                                                                     |
| 581 |    497.158612 |     18.549391 | Matt Wilkins                                                                                                                                                                         |
| 582 |    430.845763 |    518.099837 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 583 |   1001.516740 |    670.944917 | Gareth Monger                                                                                                                                                                        |
| 584 |    922.890547 |    142.409220 | NA                                                                                                                                                                                   |
| 585 |     57.387506 |    728.357566 | Ignacio Contreras                                                                                                                                                                    |
| 586 |    952.422238 |    538.025787 | T. Michael Keesey                                                                                                                                                                    |
| 587 |    337.872088 |    594.909662 | Gareth Monger                                                                                                                                                                        |
| 588 |    267.382735 |    498.854220 | Abraão Leite                                                                                                                                                                         |
| 589 |    217.659184 |    777.781592 | Tauana J. Cunha                                                                                                                                                                      |
| 590 |    907.124391 |    548.841881 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 591 |    297.370681 |    223.885075 | NA                                                                                                                                                                                   |
| 592 |    143.368624 |    163.490732 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 593 |    202.868725 |    785.453643 | NA                                                                                                                                                                                   |
| 594 |    334.679940 |    582.274697 | Margot Michaud                                                                                                                                                                       |
| 595 |    363.341170 |    704.129886 | Tasman Dixon                                                                                                                                                                         |
| 596 |    889.899567 |     71.712127 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 597 |    488.539502 |    723.012106 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 598 |    179.885065 |     47.162211 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 599 |    995.472207 |    217.072014 | Steven Traver                                                                                                                                                                        |
| 600 |    978.834676 |    520.349198 | Erika Schumacher                                                                                                                                                                     |
| 601 |    198.372068 |    774.069199 | Scott Hartman                                                                                                                                                                        |
| 602 |     72.526557 |    127.843845 | Rebecca Groom                                                                                                                                                                        |
| 603 |    635.799297 |    132.597031 | M Hutchinson                                                                                                                                                                         |
| 604 |    271.030794 |    570.342374 | Zimices                                                                                                                                                                              |
| 605 |    505.494351 |    649.595447 | Tyler Greenfield                                                                                                                                                                     |
| 606 |   1011.944038 |    363.945797 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 607 |    501.959094 |    537.701077 | Matt Crook                                                                                                                                                                           |
| 608 |   1020.931813 |     88.202356 | NASA                                                                                                                                                                                 |
| 609 |    558.807256 |    781.254338 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 610 |    942.315086 |    132.168159 | Ferran Sayol                                                                                                                                                                         |
| 611 |    491.735215 |     67.456523 | Matt Crook                                                                                                                                                                           |
| 612 |    760.079190 |    600.365118 | Zimices                                                                                                                                                                              |
| 613 |     37.476277 |    240.168698 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                           |
| 614 |    620.342976 |    718.050738 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 615 |    582.458299 |    107.018316 | Tracy A. Heath                                                                                                                                                                       |
| 616 |   1013.700408 |    254.973161 | Tasman Dixon                                                                                                                                                                         |
| 617 |   1013.037647 |    621.042392 | Skye McDavid                                                                                                                                                                         |
| 618 |    307.568679 |    108.610149 | Joanna Wolfe                                                                                                                                                                         |
| 619 |    967.891493 |    414.485090 | Trond R. Oskars                                                                                                                                                                      |
| 620 |    748.611756 |    790.218037 | T. Michael Keesey                                                                                                                                                                    |
| 621 |    879.542033 |    541.123162 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 622 |     59.965712 |    190.459225 | Michelle Site                                                                                                                                                                        |
| 623 |    459.077739 |    526.953495 | Margot Michaud                                                                                                                                                                       |
| 624 |     55.241941 |    508.375932 | Courtney Rockenbach                                                                                                                                                                  |
| 625 |    620.620388 |    641.159606 | Birgit Szabo                                                                                                                                                                         |
| 626 |    665.205896 |    230.908587 | Matt Crook                                                                                                                                                                           |
| 627 |    547.799312 |    438.726722 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 628 |     24.387679 |    318.365634 | NA                                                                                                                                                                                   |
| 629 |    729.402077 |    356.563482 | Matt Crook                                                                                                                                                                           |
| 630 |    318.315677 |    263.033749 | Cristina Guijarro                                                                                                                                                                    |
| 631 |    712.519893 |    263.722890 | Melissa Broussard                                                                                                                                                                    |
| 632 |    866.037492 |     31.208514 | CNZdenek                                                                                                                                                                             |
| 633 |    646.952154 |    759.396116 | Terpsichores                                                                                                                                                                         |
| 634 |    125.329250 |    351.896974 | Sarah Werning                                                                                                                                                                        |
| 635 |    682.195768 |    542.640175 | Margot Michaud                                                                                                                                                                       |
| 636 |     54.089742 |    790.255192 | Jagged Fang Designs                                                                                                                                                                  |
| 637 |    970.243595 |    780.077268 | Dean Schnabel                                                                                                                                                                        |
| 638 |    910.647436 |    132.183720 | Tasman Dixon                                                                                                                                                                         |
| 639 |    126.253417 |    379.729902 | Joanna Wolfe                                                                                                                                                                         |
| 640 |     40.380498 |    634.516241 | Ferran Sayol                                                                                                                                                                         |
| 641 |    723.772763 |    329.924041 | NA                                                                                                                                                                                   |
| 642 |    388.203741 |    740.901051 | Markus A. Grohme                                                                                                                                                                     |
| 643 |    740.733011 |    524.084518 | Jagged Fang Designs                                                                                                                                                                  |
| 644 |    609.498631 |    229.103570 | Sean McCann                                                                                                                                                                          |
| 645 |    890.599216 |    447.149979 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 646 |    963.012046 |     16.822367 | Gareth Monger                                                                                                                                                                        |
| 647 |    420.323624 |     59.445924 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 648 |    337.734426 |     35.181260 | Xavier Giroux-Bougard                                                                                                                                                                |
| 649 |    750.087083 |    593.146572 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
| 650 |    819.466146 |     81.505726 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 651 |    766.199704 |    418.943316 | Armin Reindl                                                                                                                                                                         |
| 652 |    895.470698 |    335.979636 | Matt Crook                                                                                                                                                                           |
| 653 |    733.728263 |    593.531768 | Gareth Monger                                                                                                                                                                        |
| 654 |     13.932643 |    788.226728 | Margot Michaud                                                                                                                                                                       |
| 655 |    173.029305 |    123.184286 | Andy Wilson                                                                                                                                                                          |
| 656 |    109.445637 |    792.488522 | Matt Crook                                                                                                                                                                           |
| 657 |    867.089378 |    123.051585 | NA                                                                                                                                                                                   |
| 658 |    148.271881 |    478.569865 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                          |
| 659 |    411.735154 |    535.769767 | Matt Crook                                                                                                                                                                           |
| 660 |    408.321842 |     70.133796 | NA                                                                                                                                                                                   |
| 661 |    508.619763 |    126.030069 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 662 |    173.361564 |    744.674368 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 663 |    285.875906 |    292.414184 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 664 |   1006.807904 |    714.621874 | Kent Elson Sorgon                                                                                                                                                                    |
| 665 |    785.815311 |    724.799258 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 666 |    139.161545 |    702.328895 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                                       |
| 667 |     43.840765 |    535.200970 | Inessa Voet                                                                                                                                                                          |
| 668 |    264.042718 |    549.591593 | NA                                                                                                                                                                                   |
| 669 |    165.571027 |    769.697106 | Steven Traver                                                                                                                                                                        |
| 670 |     12.968952 |    719.993025 | NA                                                                                                                                                                                   |
| 671 |    953.136568 |    138.300357 | Scott Hartman                                                                                                                                                                        |
| 672 |    964.147529 |    430.061460 | \[unknown\]                                                                                                                                                                          |
| 673 |    496.155597 |    524.592053 | T. Michael Keesey                                                                                                                                                                    |
| 674 |    570.525412 |    234.282810 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 675 |    599.594241 |    294.854850 | Gareth Monger                                                                                                                                                                        |
| 676 |    674.906482 |    158.739281 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 677 |     29.110986 |    788.590107 | Matt Crook                                                                                                                                                                           |
| 678 |    190.284330 |    396.028418 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                                     |
| 679 |    303.078404 |    445.221739 | terngirl                                                                                                                                                                             |
| 680 |    452.784813 |    789.123948 | Matt Crook                                                                                                                                                                           |
| 681 |    666.257225 |    631.887192 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 682 |    403.429192 |    467.572491 | Chuanixn Yu                                                                                                                                                                          |
| 683 |    902.612174 |    664.799959 | Armin Reindl                                                                                                                                                                         |
| 684 |    740.884475 |    582.441143 | Felix Vaux                                                                                                                                                                           |
| 685 |    348.799373 |    306.430178 | Ingo Braasch                                                                                                                                                                         |
| 686 |    639.895922 |     14.963154 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 687 |    411.415214 |     77.322769 | Tasman Dixon                                                                                                                                                                         |
| 688 |    206.129741 |    396.368135 | NA                                                                                                                                                                                   |
| 689 |    166.706596 |     35.598684 | Chris huh                                                                                                                                                                            |
| 690 |    273.041588 |    333.126567 | Matt Crook                                                                                                                                                                           |
| 691 |    520.023465 |    227.746565 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 692 |    705.156889 |    219.233071 | NA                                                                                                                                                                                   |
| 693 |    537.193196 |     67.391691 | Matt Crook                                                                                                                                                                           |
| 694 |    530.433130 |    721.359103 | Christoph Schomburg                                                                                                                                                                  |
| 695 |    145.345867 |    386.611870 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 696 |    978.334553 |    708.218875 | NA                                                                                                                                                                                   |
| 697 |    405.228768 |    402.294443 | Jagged Fang Designs                                                                                                                                                                  |
| 698 |    419.415109 |    190.277576 | Thibaut Brunet                                                                                                                                                                       |
| 699 |    772.397317 |    782.939186 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 700 |    827.501675 |    340.817173 | T. Michael Keesey                                                                                                                                                                    |
| 701 |     33.837597 |    720.486849 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                       |
| 702 |    295.674495 |    406.208295 | NA                                                                                                                                                                                   |
| 703 |    334.242838 |    223.662661 | Ferran Sayol                                                                                                                                                                         |
| 704 |    984.064940 |    238.798187 | T. Michael Keesey                                                                                                                                                                    |
| 705 |    951.895898 |    438.321371 | Rebecca Groom                                                                                                                                                                        |
| 706 |   1017.083935 |    481.595017 | Jaime Headden                                                                                                                                                                        |
| 707 |    215.356119 |    269.717253 | Gareth Monger                                                                                                                                                                        |
| 708 |    458.938180 |    137.128028 | Sarah Werning                                                                                                                                                                        |
| 709 |     46.900386 |    407.590799 | Margot Michaud                                                                                                                                                                       |
| 710 |   1012.977708 |    117.163729 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                                       |
| 711 |    725.277852 |    498.479667 | Gareth Monger                                                                                                                                                                        |
| 712 |    283.587978 |    717.093046 | Matt Crook                                                                                                                                                                           |
| 713 |    304.576531 |     25.501156 | Jagged Fang Designs                                                                                                                                                                  |
| 714 |    370.913155 |    217.566935 | Jack Mayer Wood                                                                                                                                                                      |
| 715 |    928.874225 |    617.355806 | Margot Michaud                                                                                                                                                                       |
| 716 |    397.892835 |     36.446893 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                                |
| 717 |     27.030385 |    519.980715 | Ferran Sayol                                                                                                                                                                         |
| 718 |    531.378027 |    666.211464 | Steven Traver                                                                                                                                                                        |
| 719 |     80.368720 |    521.040189 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 720 |    464.818048 |    768.035148 | Collin Gross                                                                                                                                                                         |
| 721 |    394.148539 |    772.549466 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 722 |    337.703975 |    399.298901 | NA                                                                                                                                                                                   |
| 723 |    246.283289 |    286.859554 | Lukasiniho                                                                                                                                                                           |
| 724 |   1012.713303 |    757.024346 | Andy Wilson                                                                                                                                                                          |
| 725 |     72.838053 |    604.387675 | Margot Michaud                                                                                                                                                                       |
| 726 |    786.681365 |    779.530221 | Matt Crook                                                                                                                                                                           |
| 727 |    687.483084 |    113.970535 | Margot Michaud                                                                                                                                                                       |
| 728 |     75.236970 |    200.094576 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                            |
| 729 |    818.248716 |    111.765095 | Matt Crook                                                                                                                                                                           |
| 730 |    610.764973 |    734.926859 | Markus A. Grohme                                                                                                                                                                     |
| 731 |    140.368210 |    295.244978 | Scott Hartman                                                                                                                                                                        |
| 732 |     11.210130 |     81.956478 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 733 |    273.799086 |    535.677823 | NA                                                                                                                                                                                   |
| 734 |     19.476904 |     65.587577 | Jiekun He                                                                                                                                                                            |
| 735 |   1002.731006 |    729.711695 | Scott Hartman                                                                                                                                                                        |
| 736 |    404.807756 |     24.025613 | Steven Traver                                                                                                                                                                        |
| 737 |     23.387987 |    344.000985 | Zimices                                                                                                                                                                              |
| 738 |    829.761474 |    401.418872 | Melissa Broussard                                                                                                                                                                    |
| 739 |     65.027701 |    111.401297 | Ignacio Contreras                                                                                                                                                                    |
| 740 |    590.611792 |    227.282135 | Margot Michaud                                                                                                                                                                       |
| 741 |    150.729987 |    704.667292 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                               |
| 742 |    805.217966 |    236.598540 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 743 |    926.511665 |    352.407246 | Qiang Ou                                                                                                                                                                             |
| 744 |    253.577778 |    649.649347 | Andy Wilson                                                                                                                                                                          |
| 745 |    268.820662 |    374.318789 | S.Martini                                                                                                                                                                            |
| 746 |    971.953613 |    229.880186 | Matt Crook                                                                                                                                                                           |
| 747 |   1013.569212 |    158.250911 | Scott Reid                                                                                                                                                                           |
| 748 |    234.815559 |    455.105222 | Michelle Site                                                                                                                                                                        |
| 749 |    552.135763 |     44.746381 | David Orr                                                                                                                                                                            |
| 750 |    874.283447 |    617.827780 | Sarah Werning                                                                                                                                                                        |
| 751 |    252.096844 |     83.493615 | Matt Crook                                                                                                                                                                           |
| 752 |    400.301066 |    185.380791 | Armin Reindl                                                                                                                                                                         |
| 753 |    696.783501 |    364.414511 | NA                                                                                                                                                                                   |
| 754 |    221.838356 |    160.475139 | Rebecca Groom                                                                                                                                                                        |
| 755 |    842.976147 |    106.684278 | Tasman Dixon                                                                                                                                                                         |
| 756 |     93.605645 |    272.518846 | Zimices                                                                                                                                                                              |
| 757 |    523.501776 |    365.199411 | Chris huh                                                                                                                                                                            |
| 758 |    429.126938 |     77.801493 | Chuanixn Yu                                                                                                                                                                          |
| 759 |   1015.249315 |    458.787297 | Jagged Fang Designs                                                                                                                                                                  |
| 760 |    382.160340 |    459.227242 | Steven Traver                                                                                                                                                                        |
| 761 |    532.700052 |    740.110008 | Birgit Lang                                                                                                                                                                          |
| 762 |    778.711453 |    743.772101 | Matt Crook                                                                                                                                                                           |
| 763 |    741.034390 |    779.729629 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 764 |    683.461120 |    628.536086 | Elisabeth Östman                                                                                                                                                                     |
| 765 |    624.165044 |    198.302756 | Ferran Sayol                                                                                                                                                                         |
| 766 |    960.289993 |    195.982965 | Michael Scroggie                                                                                                                                                                     |
| 767 |    552.369120 |    322.159456 | Kai R. Caspar                                                                                                                                                                        |
| 768 |    901.843120 |    276.089683 | Markus A. Grohme                                                                                                                                                                     |
| 769 |    729.457626 |    255.039198 | Zimices                                                                                                                                                                              |
| 770 |    696.264207 |    641.692665 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                                     |
| 771 |    314.390108 |    173.808387 | Margot Michaud                                                                                                                                                                       |
| 772 |    107.996620 |    377.688943 | Chris huh                                                                                                                                                                            |
| 773 |    489.109865 |    590.706069 | Chris huh                                                                                                                                                                            |
| 774 |    732.322560 |    615.597401 | Gareth Monger                                                                                                                                                                        |
| 775 |    709.929078 |    468.854412 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 776 |    874.750591 |     76.366324 | Joanna Wolfe                                                                                                                                                                         |
| 777 |   1009.145899 |    633.941650 | Rebecca Groom                                                                                                                                                                        |
| 778 |    190.324058 |    425.241298 | NA                                                                                                                                                                                   |
| 779 |    283.044981 |    298.115249 | CNZdenek                                                                                                                                                                             |
| 780 |    677.834431 |     72.584074 | Anthony Caravaggi                                                                                                                                                                    |
| 781 |    442.557609 |    316.458629 | Jagged Fang Designs                                                                                                                                                                  |
| 782 |    501.246541 |    185.279145 | Dmitry Bogdanov                                                                                                                                                                      |
| 783 |   1002.698659 |     13.664408 | Steven Traver                                                                                                                                                                        |
| 784 |    683.257919 |    720.583832 | Tasman Dixon                                                                                                                                                                         |
| 785 |    327.661407 |    165.434652 | NA                                                                                                                                                                                   |
| 786 |    721.722387 |    605.794307 | Yan Wong                                                                                                                                                                             |
| 787 |    876.692452 |    593.466576 | Erika Schumacher                                                                                                                                                                     |
| 788 |    449.436556 |    297.318189 | Becky Barnes                                                                                                                                                                         |
| 789 |    586.758668 |    698.452544 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 790 |    231.397548 |    658.446778 | Yan Wong                                                                                                                                                                             |
| 791 |    477.275676 |    544.634890 | Scott Reid                                                                                                                                                                           |
| 792 |     61.020539 |    458.221427 | Arthur S. Brum                                                                                                                                                                       |
| 793 |    887.601472 |    500.286542 | Matt Crook                                                                                                                                                                           |
| 794 |    813.433262 |    405.679237 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 795 |    872.764612 |    425.820584 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 796 |    312.892884 |    214.040538 | Chris huh                                                                                                                                                                            |
| 797 |    773.143521 |     74.714318 | Matt Crook                                                                                                                                                                           |
| 798 |    534.907031 |    765.681934 | Emily Willoughby                                                                                                                                                                     |
| 799 |    550.343565 |    151.901252 | Kai R. Caspar                                                                                                                                                                        |
| 800 |    772.360807 |    219.327188 | Steven Traver                                                                                                                                                                        |
| 801 |    346.147368 |    696.601877 | Terpsichores                                                                                                                                                                         |
| 802 |    993.652856 |    738.045203 | Margot Michaud                                                                                                                                                                       |
| 803 |    549.305681 |    163.656482 | Zimices                                                                                                                                                                              |
| 804 |    543.677225 |    528.087469 | Kamil S. Jaron                                                                                                                                                                       |
| 805 |    739.822750 |    546.710037 | Tasman Dixon                                                                                                                                                                         |
| 806 |    751.357506 |    280.343917 | Zimices                                                                                                                                                                              |
| 807 |    714.536324 |    425.492643 | Andy Wilson                                                                                                                                                                          |
| 808 |    450.193065 |     65.784883 | Rebecca Groom                                                                                                                                                                        |
| 809 |    357.953524 |    211.853606 | Sarah Werning                                                                                                                                                                        |
| 810 |     80.602442 |    308.950960 | NA                                                                                                                                                                                   |
| 811 |    431.369003 |    445.577132 | Gareth Monger                                                                                                                                                                        |
| 812 |    277.748555 |    752.169752 | Markus A. Grohme                                                                                                                                                                     |
| 813 |     99.065097 |    332.486128 | Kai R. Caspar                                                                                                                                                                        |
| 814 |    992.719961 |    771.569242 | Jack Mayer Wood                                                                                                                                                                      |
| 815 |    988.686666 |    412.094160 | Melissa Broussard                                                                                                                                                                    |
| 816 |    818.672142 |    436.534469 | Scott Hartman                                                                                                                                                                        |
| 817 |    165.439528 |    459.284707 | Matt Crook                                                                                                                                                                           |
| 818 |    137.284945 |    277.844797 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 819 |    182.912581 |     72.578238 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 820 |    326.916225 |    777.044547 | Karla Martinez                                                                                                                                                                       |
| 821 |    568.690645 |    514.245046 | Gareth Monger                                                                                                                                                                        |
| 822 |    705.502577 |    570.881647 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 823 |    278.810225 |    392.993060 | Zimices                                                                                                                                                                              |
| 824 |    773.002495 |     33.568228 | U.S. National Park Service (vectorized by William Gearty)                                                                                                                            |
| 825 |    751.837305 |    492.895724 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 826 |    220.925894 |     53.640319 | Birgit Lang                                                                                                                                                                          |
| 827 |    840.226313 |    688.705992 | Emily Willoughby                                                                                                                                                                     |
| 828 |    967.298449 |    591.501719 | Michelle Site                                                                                                                                                                        |
| 829 |     58.746746 |     51.575257 | Steven Traver                                                                                                                                                                        |
| 830 |    358.779908 |    571.501042 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                                          |
| 831 |    845.666062 |    738.661579 | Scott Hartman                                                                                                                                                                        |
| 832 |    493.190457 |    609.712608 | NA                                                                                                                                                                                   |
| 833 |     79.200914 |     84.063849 | Scott Hartman                                                                                                                                                                        |
| 834 |    690.711155 |    527.129198 | NA                                                                                                                                                                                   |
| 835 |    856.266743 |    227.337260 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                        |
| 836 |     71.812512 |    343.152870 | Zimices                                                                                                                                                                              |
| 837 |    542.416485 |    678.160598 | Jagged Fang Designs                                                                                                                                                                  |
| 838 |    858.746513 |     17.144482 | T. Michael Keesey                                                                                                                                                                    |
| 839 |    556.700364 |    501.673380 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 840 |    713.071741 |    722.558041 | Mattia Menchetti                                                                                                                                                                     |
| 841 |    312.519567 |    557.029999 | Tasman Dixon                                                                                                                                                                         |
| 842 |    611.903493 |    728.446572 | RS                                                                                                                                                                                   |
| 843 |    479.581907 |    712.540190 | Kamil S. Jaron                                                                                                                                                                       |
| 844 |    293.482804 |    704.880384 | Felix Vaux                                                                                                                                                                           |
| 845 |    624.296495 |    311.833149 | Kamil S. Jaron                                                                                                                                                                       |
| 846 |    851.309502 |    362.396064 | Jagged Fang Designs                                                                                                                                                                  |
| 847 |    209.195827 |    653.820933 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 848 |    971.430164 |    350.224042 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 849 |    660.223586 |    433.593577 | Collin Gross                                                                                                                                                                         |
| 850 |    938.385799 |    374.390801 | T. Michael Keesey                                                                                                                                                                    |
| 851 |    963.803343 |    534.006659 | Tasman Dixon                                                                                                                                                                         |
| 852 |    962.644577 |    730.955654 | Matt Crook                                                                                                                                                                           |
| 853 |    502.374823 |    791.165542 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 854 |    462.713704 |    151.357137 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 855 |    616.671314 |    788.739500 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                                      |
| 856 |    877.453368 |    227.796346 | Michelle Site                                                                                                                                                                        |
| 857 |    741.887396 |    511.782115 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 858 |    326.946336 |    427.464099 | Geoff Shaw                                                                                                                                                                           |
| 859 |    554.575752 |    466.740609 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                                          |
| 860 |    386.490634 |     53.677104 | Matt Crook                                                                                                                                                                           |
| 861 |    234.400808 |     91.697671 | Christoph Schomburg                                                                                                                                                                  |
| 862 |    514.990972 |    499.063723 | Rebecca Groom                                                                                                                                                                        |
| 863 |    564.343576 |    197.706732 | Jaime Headden                                                                                                                                                                        |
| 864 |    507.426153 |    321.259794 | Margret Flinsch, vectorized by Zimices                                                                                                                                               |
| 865 |    178.291390 |    405.752161 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 866 |    890.148730 |    665.418245 | Matt Crook                                                                                                                                                                           |
| 867 |     34.986294 |    401.063383 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 868 |    335.971566 |    297.099524 | Scott Hartman                                                                                                                                                                        |
| 869 |    104.133171 |    567.982328 | B Kimmel                                                                                                                                                                             |
| 870 |      4.333930 |    549.724478 | NA                                                                                                                                                                                   |
| 871 |    817.526251 |    128.763107 | Courtney Rockenbach                                                                                                                                                                  |
| 872 |    968.043676 |    701.607509 | Nobu Tamura                                                                                                                                                                          |
| 873 |    131.012994 |    112.044713 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 874 |    725.084376 |    274.951415 | Margot Michaud                                                                                                                                                                       |
| 875 |    774.863828 |    615.774828 | Matt Crook                                                                                                                                                                           |
| 876 |    279.192057 |    747.287600 | Tod Robbins                                                                                                                                                                          |
| 877 |    970.628634 |    388.228876 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 878 |    634.551343 |    709.891054 | Javier Luque                                                                                                                                                                         |
| 879 |    222.361726 |    291.407699 | T. Michael Keesey                                                                                                                                                                    |
| 880 |    784.840666 |    328.294842 | Zimices                                                                                                                                                                              |
| 881 |    999.553738 |    357.306447 | Kai R. Caspar                                                                                                                                                                        |
| 882 |    853.139071 |    480.851210 | Baheerathan Murugavel                                                                                                                                                                |
| 883 |    493.857216 |    166.685844 | Margot Michaud                                                                                                                                                                       |
| 884 |    535.005937 |    226.579262 | Margot Michaud                                                                                                                                                                       |
| 885 |    577.061504 |    769.802534 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 886 |    786.607877 |    420.786869 | Scott Hartman                                                                                                                                                                        |
| 887 |    818.344889 |    168.699058 | Christoph Schomburg                                                                                                                                                                  |
| 888 |    646.538171 |    309.471940 | Michael Scroggie                                                                                                                                                                     |
| 889 |    899.458204 |    680.676862 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 890 |    734.021219 |     73.876010 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                            |
| 891 |    389.491134 |    614.803030 | T. Michael Keesey                                                                                                                                                                    |
| 892 |    552.661617 |    367.696500 | Terpsichores                                                                                                                                                                         |
| 893 |    807.629691 |    442.356065 | NA                                                                                                                                                                                   |
| 894 |    282.379206 |     88.643232 | Tracy A. Heath                                                                                                                                                                       |
| 895 |    363.268789 |    274.673564 | Scott Reid                                                                                                                                                                           |
| 896 |     16.822953 |      7.916886 | Michelle Site                                                                                                                                                                        |
| 897 |    777.841517 |      5.188763 | Melissa Broussard                                                                                                                                                                    |
| 898 |    716.444028 |    351.375018 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 899 |    136.341313 |    266.756691 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 900 |    610.916536 |     76.360454 | T. Michael Keesey                                                                                                                                                                    |
| 901 |    276.283491 |    103.478876 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                                |
| 902 |    703.797801 |    327.511858 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 903 |    635.185893 |    493.162678 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                        |
| 904 |    781.071875 |    398.265171 | T. Michael Keesey                                                                                                                                                                    |
| 905 |    289.099070 |    265.953000 | Gareth Monger                                                                                                                                                                        |
| 906 |    483.788195 |    641.260388 | Daniel Stadtmauer                                                                                                                                                                    |
| 907 |    611.348330 |    213.643024 | Tasman Dixon                                                                                                                                                                         |
| 908 |    777.221988 |    257.443984 | L. Shyamal                                                                                                                                                                           |
| 909 |    660.031652 |    674.121708 | Gareth Monger                                                                                                                                                                        |
| 910 |    891.538634 |     82.142126 | Ferran Sayol                                                                                                                                                                         |
| 911 |    133.555377 |    158.330152 | Matt Crook                                                                                                                                                                           |
| 912 |    363.620477 |    787.589862 | Matt Crook                                                                                                                                                                           |
| 913 |    929.297524 |    732.414548 | NA                                                                                                                                                                                   |

    #> Your tweet has been posted!
