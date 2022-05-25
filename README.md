
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

Sean McCann, Melissa Broussard, Steve Hillebrand/U. S. Fish and Wildlife
Service (source photo), T. Michael Keesey (vectorization), Zimices, Matt
Martyniuk, Gabriela Palomo-Munoz, Jagged Fang Designs, C. Camilo
Julián-Caballero, Tauana J. Cunha, Jonathan Wells, Kanako
Bessho-Uehara, Dmitry Bogdanov (vectorized by T. Michael Keesey), T.
Michael Keesey (after Ponomarenko), Michael Scroggie, Steven Haddock
• Jellywatch.org, Nobu Tamura, vectorized by Zimices, T. Michael
Keesey, Yan Wong, Pedro de Siracusa, Skye McDavid, Geoff Shaw, Jiekun
He, Carlos Cano-Barbacil, Nobu Tamura (vectorized by T. Michael Keesey),
Mark Witton, Matt Crook, Mali’o Kodis, photograph property of National
Museums of Northern Ireland, Arthur Grosset (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Steven Traver, John
Conway, Ingo Braasch, , Anthony Caravaggi, Sarah Werning, Iain Reid,
Steven Coombs, Gareth Monger, Bennet McComish, photo by Hans Hillewaert,
nicubunu, Tony Ayling, Chris huh, Erika Schumacher, Smokeybjb, Cesar
Julian, Nobu Tamura, Original drawing by Nobu Tamura, vectorized by
Roberto Díaz Sibaja, Ferran Sayol, Dean Schnabel, Maxime Dahirel, Julio
Garza, Scott Hartman, Zachary Quigley, CNZdenek, Ignacio Contreras,
Gregor Bucher, Max Farnworth, Roberto Díaz Sibaja, Lip Kee Yap
(vectorized by T. Michael Keesey), Tasman Dixon, Inessa Voet, Andy
Wilson, Alexandre Vong, T. Michael Keesey (photo by Bc999 \[Black
crow\]), David Orr, Luc Viatour (source photo) and Andreas Plank,
Aviceda (photo) & T. Michael Keesey, Ellen Edmonson and Hugh Chrisp
(vectorized by T. Michael Keesey), Jaime Headden, Alexander
Schmidt-Lebuhn, Joseph Wolf, 1863 (vectorization by Dinah Challen),
Charles Doolittle Walcott (vectorized by T. Michael Keesey), Alex
Slavenko, T. Tischler, Mo Hassan, Michelle Site, Matthew E. Clapham,
Markus A. Grohme, Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Lankester Edwin Ray
(vectorized by T. Michael Keesey), Beth Reinke, Andrew A. Farke, Margot
Michaud, Harold N Eyster, Daniel Jaron, Joanna Wolfe, Kristina Gagalova,
Becky Barnes, Blair Perry, Birgit Lang, Brad McFeeters (vectorized by T.
Michael Keesey), Noah Schlottman, photo from Casey Dunn, Felix Vaux,
Mali’o Kodis, image from the “Proceedings of the Zoological Society of
London”, FunkMonk, Nina Skinner, George Edward Lodge (modified by T.
Michael Keesey), Maija Karala, Mariana Ruiz Villarreal (modified by T.
Michael Keesey), Jaime Chirinos (vectorized by T. Michael Keesey),
Mareike C. Janiak, Scott Hartman (modified by T. Michael Keesey), Hugo
Gruson, Ekaterina Kopeykina (vectorized by T. Michael Keesey),
www.studiospectre.com, 于川云, Rebecca Groom, Prathyush Thomas, Tyler
Greenfield, Sam Droege (photo) and T. Michael Keesey (vectorization),
Tracy A. Heath, Christoph Schomburg, Mathieu Pélissié, Mason McNair,
Milton Tan, Kanchi Nanjo, Noah Schlottman, photo by Gustav Paulay for
Moorea Biocode, Kailah Thorn & Mark Hutchinson, Xvazquez (vectorized by
William Gearty), Juan Carlos Jerí, Darren Naish (vectorize by T. Michael
Keesey), Ray Simpson (vectorized by T. Michael Keesey), Chris Jennings
(Risiatto), Kamil S. Jaron, Meliponicultor Itaymbere, Lukasiniho, DW
Bapst (modified from Bulman, 1970), Matt Martyniuk (modified by
Serenchia), Jack Mayer Wood, S.Martini, Noah Schlottman, T. Michael
Keesey (after James & al.), Jon M Laurent, Matus Valach, Mike Hanson,
Armin Reindl, Emily Willoughby, Hanyong Pu, Yoshitsugu Kobayashi,
Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia &
T. Michael Keesey, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Noah Schlottman,
photo from Moorea Biocode, Manabu Bessho-Uehara, Original drawing by
Antonov, vectorized by Roberto Díaz Sibaja, Mykle Hoban, Konsta
Happonen, Unknown (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, \[unknown\], Heinrich Harder (vectorized by William
Gearty), Jake Warner, Tarique Sani (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Roberto Diaz Sibaja, based on
Domser, Smith609 and T. Michael Keesey, Noah Schlottman, photo by Hans
De Blauwe, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Haplochromis
(vectorized by T. Michael Keesey), Scott Reid, Mette Aumala, Abraão
Leite, Dmitry Bogdanov, Ramona J Heim, Matt Martyniuk (vectorized by T.
Michael Keesey), Karl Ragnar Gjertsen (vectorized by T. Michael Keesey),
Yusan Yang, Claus Rebler, Apokryltaros (vectorized by T. Michael
Keesey), Filip em, Katie S. Collins, Dave Souza (vectorized by T.
Michael Keesey), Mali’o Kodis, photograph by John Slapcinsky, Jim Bendon
(photography) and T. Michael Keesey (vectorization), Chris Hay,
Ghedoghedo (vectorized by T. Michael Keesey), Kent Sorgon, Oscar
Sanisidro, T. Michael Keesey (vectorization) and Tony Hisgett
(photography), Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Rene Martin,
Caroline Harding, MAF (vectorized by T. Michael Keesey), Steven
Blackwood, Eyal Bartov, Ellen Edmonson (illustration) and Timothy J.
Bartley (silhouette), Ryan Cupo, Dmitry Bogdanov (modified by T. Michael
Keesey), George Edward Lodge (vectorized by T. Michael Keesey), L.
Shyamal, V. Deepak, Eduard Solà (vectorized by T. Michael Keesey),
Sharon Wegner-Larsen, Stephen O’Connor (vectorized by T. Michael
Keesey), Collin Gross, Peileppe, Fernando Carezzano, T. Michael Keesey
(vectorization) and Nadiatalent (photography), zoosnow, Noah Schlottman,
photo by Carol Cummings, Xavier Giroux-Bougard, Tambja (vectorized by T.
Michael Keesey), M. Garfield & K. Anderson (modified by T. Michael
Keesey), Jose Carlos Arenas-Monroy, Zimices / Julián Bayona, xgirouxb,
Ieuan Jones, Andreas Trepte (vectorized by T. Michael Keesey), Duane
Raver (vectorized by T. Michael Keesey), Smokeybjb (vectorized by T.
Michael Keesey), Pete Buchholz, Matt Wilkins (photo by Patrick
Kavanagh), Michael Scroggie, from original photograph by Gary M. Stolz,
USFWS (original photograph in public domain)., Roderic Page and Lois
Page, Terpsichores, T. Michael Keesey (after Colin M. L. Burnett), T.
Michael Keesey and Tanetahi, FunkMonk (Michael B.H.; vectorized by T.
Michael Keesey), Davidson Sodré, Sergio A. Muñoz-Gómez, Meyer-Wachsmuth
I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>).
Vectorization by Y. Wong, Maxwell Lefroy (vectorized by T. Michael
Keesey), Dantheman9758 (vectorized by T. Michael Keesey), Daniel
Stadtmauer, Jaime Headden (vectorized by T. Michael Keesey), Manabu
Sakamoto, Tyler Greenfield and Dean Schnabel, Riccardo Percudani, J
Levin W (illustration) and T. Michael Keesey (vectorization), Todd
Marshall, vectorized by Zimices, Alexandra van der Geer, Benjamint444,
Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong), Jebulon
(vectorized by T. Michael Keesey), Heinrich Harder (vectorized by T.
Michael Keesey), Shyamal, Yan Wong from illustration by Jules Richard
(1907), Mali’o Kodis, traced image from the National Science
Foundation’s Turbellarian Taxonomic Database, Yan Wong from drawing by
T. F. Zimmermann, Louis Ranjard, Nicolas Huet le Jeune and Jean-Gabriel
Prêtre (vectorized by T. Michael Keesey), Paul Baker (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Lisa M. “Pixxl”
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Robbie N. Cada (vectorized by T. Michael Keesey), Dinah Challen,
Michele Tobias, Martien Brand (original photo), Renato Santos (vector
silhouette), Kai R. Caspar, Craig Dylke, Obsidian Soul (vectorized by T.
Michael Keesey), James R. Spotila and Ray Chatterji, Darius Nau, Hans
Hillewaert (vectorized by T. Michael Keesey), Mathieu Basille, Gopal
Murali, Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M.
Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Chuanixn
Yu, Ernst Haeckel (vectorized by T. Michael Keesey), Noah Schlottman,
photo by Reinhard Jahn, Caleb M. Brown, Andrew A. Farke, modified from
original by Robert Bruce Horsfall, from Scott 1912, JCGiron, Francesco
“Architetto” Rollandin, Esme Ashe-Jepson, RS, Neil Kelley, Pranav Iyer
(grey ideas), Chris A. Hamilton, Smokeybjb (modified by Mike Keesey),
Chase Brownstein, Notafly (vectorized by T. Michael Keesey), David Liao,
Matt Dempsey, Christine Axon, Matt Celeskey, Nobu Tamura and T. Michael
Keesey, Griensteidl and T. Michael Keesey, Gustav Mützel, Mali’o Kodis,
image from the Biodiversity Heritage Library, Thea Boodhoo (photograph)
and T. Michael Keesey (vectorization), Óscar San−Isidro (vectorized by
T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                          |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    463.143672 |    245.497130 | Sean McCann                                                                                                                                                     |
|   2 |    587.161360 |    480.723486 | Melissa Broussard                                                                                                                                               |
|   3 |    827.949223 |    203.981484 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                              |
|   4 |    902.467511 |    532.672585 | Zimices                                                                                                                                                         |
|   5 |    818.789229 |    423.690163 | Matt Martyniuk                                                                                                                                                  |
|   6 |    365.570174 |    361.769411 | Gabriela Palomo-Munoz                                                                                                                                           |
|   7 |    652.802277 |    150.904003 | Zimices                                                                                                                                                         |
|   8 |    931.241882 |    404.778916 | Jagged Fang Designs                                                                                                                                             |
|   9 |    185.689412 |    280.976403 | C. Camilo Julián-Caballero                                                                                                                                      |
|  10 |    148.954705 |    225.961210 | NA                                                                                                                                                              |
|  11 |    299.364549 |    206.690809 | Tauana J. Cunha                                                                                                                                                 |
|  12 |    532.119780 |    375.386922 | Jonathan Wells                                                                                                                                                  |
|  13 |    895.817787 |     42.962393 | Kanako Bessho-Uehara                                                                                                                                            |
|  14 |    450.447844 |    618.811245 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
|  15 |    280.676842 |     50.932287 | NA                                                                                                                                                              |
|  16 |    142.127371 |    634.468068 | T. Michael Keesey (after Ponomarenko)                                                                                                                           |
|  17 |    706.526493 |    399.804238 | Jagged Fang Designs                                                                                                                                             |
|  18 |    950.895061 |    207.334764 | Michael Scroggie                                                                                                                                                |
|  19 |    802.245505 |    700.112272 | Steven Haddock • Jellywatch.org                                                                                                                                 |
|  20 |    929.605573 |    781.161196 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
|  21 |     74.045581 |    498.403902 | T. Michael Keesey                                                                                                                                               |
|  22 |    712.702692 |    533.029000 | Yan Wong                                                                                                                                                        |
|  23 |    309.262647 |    503.780316 | Pedro de Siracusa                                                                                                                                               |
|  24 |    158.622091 |    421.696458 | Gabriela Palomo-Munoz                                                                                                                                           |
|  25 |    204.501767 |    745.183241 | Skye McDavid                                                                                                                                                    |
|  26 |    826.742964 |     81.373348 | Geoff Shaw                                                                                                                                                      |
|  27 |    242.869588 |    633.974252 | Jiekun He                                                                                                                                                       |
|  28 |    757.225745 |    650.027871 | Carlos Cano-Barbacil                                                                                                                                            |
|  29 |    451.418474 |    144.100173 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  30 |    893.347095 |    604.353564 | Mark Witton                                                                                                                                                     |
|  31 |    136.939000 |     58.012259 | Matt Crook                                                                                                                                                      |
|  32 |    835.121382 |    361.556863 | Zimices                                                                                                                                                         |
|  33 |    715.837883 |    301.577300 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                       |
|  34 |    510.533687 |    748.195205 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
|  35 |    384.229528 |    710.689230 | Matt Crook                                                                                                                                                      |
|  36 |    373.162664 |    221.375058 | Steven Traver                                                                                                                                                   |
|  37 |    626.372235 |    718.192444 | Matt Crook                                                                                                                                                      |
|  38 |     61.155110 |    721.759087 | Matt Crook                                                                                                                                                      |
|  39 |    424.816009 |    725.285648 | Michael Scroggie                                                                                                                                                |
|  40 |    478.507645 |    452.394546 | Jagged Fang Designs                                                                                                                                             |
|  41 |    569.480233 |    248.583549 | John Conway                                                                                                                                                     |
|  42 |    762.426071 |    766.658338 | Ingo Braasch                                                                                                                                                    |
|  43 |    949.743045 |    117.380841 |                                                                                                                                                                 |
|  44 |    216.304508 |    162.999717 | Matt Crook                                                                                                                                                      |
|  45 |    602.648408 |    305.921822 | Matt Crook                                                                                                                                                      |
|  46 |    115.269766 |    141.193217 | Anthony Caravaggi                                                                                                                                               |
|  47 |    297.853702 |    316.020474 | Matt Crook                                                                                                                                                      |
|  48 |    855.980206 |    290.562299 | Sarah Werning                                                                                                                                                   |
|  49 |    921.243547 |    747.649078 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
|  50 |    665.224772 |    368.719764 | Jagged Fang Designs                                                                                                                                             |
|  51 |    592.883244 |    573.835823 | Iain Reid                                                                                                                                                       |
|  52 |    538.768310 |     53.385883 | Steven Coombs                                                                                                                                                   |
|  53 |    176.143688 |    321.961845 | C. Camilo Julián-Caballero                                                                                                                                      |
|  54 |    947.447751 |    354.829152 | Zimices                                                                                                                                                         |
|  55 |    697.098224 |     21.423557 | Sarah Werning                                                                                                                                                   |
|  56 |    511.868906 |    647.756983 | Matt Crook                                                                                                                                                      |
|  57 |     35.333272 |    221.848747 | T. Michael Keesey                                                                                                                                               |
|  58 |    719.801261 |    457.852217 | Gareth Monger                                                                                                                                                   |
|  59 |    752.608605 |     32.073396 | Bennet McComish, photo by Hans Hillewaert                                                                                                                       |
|  60 |    474.225788 |    497.655228 | nicubunu                                                                                                                                                        |
|  61 |    502.949981 |    304.154776 | Tony Ayling                                                                                                                                                     |
|  62 |    341.738006 |    133.457852 | Chris huh                                                                                                                                                       |
|  63 |    954.158671 |    483.286347 | Jagged Fang Designs                                                                                                                                             |
|  64 |    226.216796 |     99.310642 | Jagged Fang Designs                                                                                                                                             |
|  65 |     79.557274 |     34.998213 | Chris huh                                                                                                                                                       |
|  66 |    358.484554 |    332.362419 | Erika Schumacher                                                                                                                                                |
|  67 |    700.108083 |    606.878874 | Smokeybjb                                                                                                                                                       |
|  68 |    403.777680 |     43.794525 | Cesar Julian                                                                                                                                                    |
|  69 |     79.390364 |    775.756566 | Gareth Monger                                                                                                                                                   |
|  70 |    435.549439 |    581.280837 | Nobu Tamura                                                                                                                                                     |
|  71 |    787.362901 |    510.392450 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                              |
|  72 |    453.025324 |    549.646781 | Ferran Sayol                                                                                                                                                    |
|  73 |    306.371443 |    715.336890 | NA                                                                                                                                                              |
|  74 |    963.079471 |    689.455763 | Dean Schnabel                                                                                                                                                   |
|  75 |    758.693662 |    240.708015 | Maxime Dahirel                                                                                                                                                  |
|  76 |    935.719036 |    448.269611 | Chris huh                                                                                                                                                       |
|  77 |    367.368845 |    641.707093 | Julio Garza                                                                                                                                                     |
|  78 |    460.317291 |    323.416607 | Scott Hartman                                                                                                                                                   |
|  79 |    938.674447 |    646.928403 | Zachary Quigley                                                                                                                                                 |
|  80 |    697.783334 |     71.868190 | CNZdenek                                                                                                                                                        |
|  81 |    372.555457 |     78.586812 | Zachary Quigley                                                                                                                                                 |
|  82 |    162.903138 |    258.377613 | Gareth Monger                                                                                                                                                   |
|  83 |     76.000001 |    304.672592 | Ignacio Contreras                                                                                                                                               |
|  84 |     35.766622 |    356.060278 | Gregor Bucher, Max Farnworth                                                                                                                                    |
|  85 |     27.775313 |     99.268475 | Roberto Díaz Sibaja                                                                                                                                             |
|  86 |    390.261461 |    286.151954 | Matt Crook                                                                                                                                                      |
|  87 |    193.643717 |    558.360056 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                   |
|  88 |    634.532387 |     53.629135 | Tasman Dixon                                                                                                                                                    |
|  89 |    215.054916 |    701.895395 | Tasman Dixon                                                                                                                                                    |
|  90 |     52.978926 |    674.430260 | Matt Crook                                                                                                                                                      |
|  91 |    660.695747 |    422.925840 | Dean Schnabel                                                                                                                                                   |
|  92 |    530.855133 |    552.130109 | Chris huh                                                                                                                                                       |
|  93 |    681.510445 |    783.538407 | Inessa Voet                                                                                                                                                     |
|  94 |    991.554216 |    302.698272 | Steven Traver                                                                                                                                                   |
|  95 |    495.636460 |    181.445743 | Andy Wilson                                                                                                                                                     |
|  96 |     70.373809 |    408.819405 | Alexandre Vong                                                                                                                                                  |
|  97 |    795.522090 |    409.701078 | NA                                                                                                                                                              |
|  98 |    685.631023 |    635.835174 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                               |
|  99 |    926.682748 |    297.941069 | NA                                                                                                                                                              |
| 100 |    484.937019 |    415.420749 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 101 |    966.059214 |    517.179407 | David Orr                                                                                                                                                       |
| 102 |     33.044486 |    436.972715 | NA                                                                                                                                                              |
| 103 |    457.657436 |    378.581391 | Luc Viatour (source photo) and Andreas Plank                                                                                                                    |
| 104 |    563.146016 |     84.471192 | Jagged Fang Designs                                                                                                                                             |
| 105 |    394.013770 |    451.979161 | Aviceda (photo) & T. Michael Keesey                                                                                                                             |
| 106 |    175.459126 |    475.230765 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                |
| 107 |    169.594805 |    706.266373 | Chris huh                                                                                                                                                       |
| 108 |    594.205266 |    783.804138 | Zimices                                                                                                                                                         |
| 109 |    730.662753 |    173.762732 | Matt Crook                                                                                                                                                      |
| 110 |    415.709097 |    390.340460 | T. Michael Keesey                                                                                                                                               |
| 111 |    850.866058 |    756.300095 | Jaime Headden                                                                                                                                                   |
| 112 |    496.022925 |    334.721436 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 113 |    550.521561 |    205.601838 | NA                                                                                                                                                              |
| 114 |    359.180637 |    406.688641 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                              |
| 115 |     21.669983 |    582.770380 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                     |
| 116 |    984.864639 |    431.936318 | Alex Slavenko                                                                                                                                                   |
| 117 |     61.275454 |    376.468325 | Scott Hartman                                                                                                                                                   |
| 118 |     62.950217 |    623.960311 | T. Tischler                                                                                                                                                     |
| 119 |    111.941935 |    611.148223 | Mo Hassan                                                                                                                                                       |
| 120 |    833.196670 |    328.095973 | Michelle Site                                                                                                                                                   |
| 121 |    437.913478 |     12.685781 | Jagged Fang Designs                                                                                                                                             |
| 122 |    617.998612 |    636.654276 | Ignacio Contreras                                                                                                                                               |
| 123 |    917.918655 |    387.986097 | Zimices                                                                                                                                                         |
| 124 |   1016.306583 |    616.416934 | Matthew E. Clapham                                                                                                                                              |
| 125 |    653.653081 |    473.571920 | Markus A. Grohme                                                                                                                                                |
| 126 |    566.798670 |    711.476824 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                             |
| 127 |    849.961099 |      5.979097 | NA                                                                                                                                                              |
| 128 |    789.162386 |    608.206988 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                           |
| 129 |    833.119094 |    402.853627 | nicubunu                                                                                                                                                        |
| 130 |    613.031909 |    616.086274 | Gabriela Palomo-Munoz                                                                                                                                           |
| 131 |    239.564048 |    530.431651 | Gabriela Palomo-Munoz                                                                                                                                           |
| 132 |    199.996949 |    297.349404 | Beth Reinke                                                                                                                                                     |
| 133 |    981.972286 |     63.176821 | Iain Reid                                                                                                                                                       |
| 134 |    146.464944 |    553.333622 | NA                                                                                                                                                              |
| 135 |    458.716027 |    726.515666 | Andrew A. Farke                                                                                                                                                 |
| 136 |    472.919997 |     70.189249 | Margot Michaud                                                                                                                                                  |
| 137 |    171.672953 |    626.697627 | T. Michael Keesey                                                                                                                                               |
| 138 |    749.369607 |    352.985540 | NA                                                                                                                                                              |
| 139 |    819.599361 |    736.322268 | Harold N Eyster                                                                                                                                                 |
| 140 |    723.531241 |    734.465242 | Jaime Headden                                                                                                                                                   |
| 141 |    855.470106 |    650.477986 | Steven Traver                                                                                                                                                   |
| 142 |     90.395605 |    263.736860 | Gabriela Palomo-Munoz                                                                                                                                           |
| 143 |    674.986813 |    301.913910 | Daniel Jaron                                                                                                                                                    |
| 144 |    108.405370 |    173.289485 | Ignacio Contreras                                                                                                                                               |
| 145 |    864.407338 |    114.082524 | Joanna Wolfe                                                                                                                                                    |
| 146 |   1001.035370 |    774.583252 | David Orr                                                                                                                                                       |
| 147 |    763.387268 |    112.529851 | Margot Michaud                                                                                                                                                  |
| 148 |    921.761023 |    726.343557 | Gareth Monger                                                                                                                                                   |
| 149 |    592.760678 |    392.210612 | Kristina Gagalova                                                                                                                                               |
| 150 |    636.329642 |    434.688499 | Gareth Monger                                                                                                                                                   |
| 151 |     11.524853 |    397.302850 | Becky Barnes                                                                                                                                                    |
| 152 |    771.042193 |    376.719847 | Blair Perry                                                                                                                                                     |
| 153 |    979.347256 |     30.200680 | Birgit Lang                                                                                                                                                     |
| 154 |    877.570809 |    449.715588 | Steven Traver                                                                                                                                                   |
| 155 |    314.145149 |     53.188720 | Steven Traver                                                                                                                                                   |
| 156 |     21.480670 |    308.488813 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                |
| 157 |     25.538924 |    538.402631 | Noah Schlottman, photo from Casey Dunn                                                                                                                          |
| 158 |    991.054019 |     39.014721 | Markus A. Grohme                                                                                                                                                |
| 159 |    314.726058 |    788.169759 | Beth Reinke                                                                                                                                                     |
| 160 |    515.821676 |     13.185340 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 161 |    416.839341 |    678.136059 | Matt Crook                                                                                                                                                      |
| 162 |    545.755522 |     22.727686 | NA                                                                                                                                                              |
| 163 |    110.057439 |    542.922989 | NA                                                                                                                                                              |
| 164 |    870.025560 |    694.799912 | NA                                                                                                                                                              |
| 165 |    433.537068 |    431.576392 | Mo Hassan                                                                                                                                                       |
| 166 |    254.487873 |    514.354987 | Felix Vaux                                                                                                                                                      |
| 167 |    952.592055 |    555.584607 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                  |
| 168 |    221.122696 |    559.876867 | FunkMonk                                                                                                                                                        |
| 169 |    896.862587 |    572.378444 | Jaime Headden                                                                                                                                                   |
| 170 |    485.982800 |    523.702378 | Nina Skinner                                                                                                                                                    |
| 171 |    413.405136 |    701.716075 | Zimices                                                                                                                                                         |
| 172 |    154.775573 |    509.727190 | Margot Michaud                                                                                                                                                  |
| 173 |    519.793782 |    102.423765 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                             |
| 174 |     76.194819 |    543.207442 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                   |
| 175 |     15.345082 |    647.921905 | Zimices                                                                                                                                                         |
| 176 |    947.459040 |    696.896533 | Zimices                                                                                                                                                         |
| 177 |    183.628908 |    576.388285 | NA                                                                                                                                                              |
| 178 |    709.950505 |    358.462841 | Maija Karala                                                                                                                                                    |
| 179 |     21.678880 |    490.992747 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 180 |    468.729971 |    286.879468 | Scott Hartman                                                                                                                                                   |
| 181 |     15.012144 |    353.227525 | Gabriela Palomo-Munoz                                                                                                                                           |
| 182 |    570.456231 |    637.463597 | Matt Crook                                                                                                                                                      |
| 183 |    499.717370 |     18.966005 | Michelle Site                                                                                                                                                   |
| 184 |    268.369030 |     88.271279 | Chris huh                                                                                                                                                       |
| 185 |    636.036978 |     12.124071 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                         |
| 186 |     11.270440 |    175.364628 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                |
| 187 |    425.364662 |    201.616957 | Mareike C. Janiak                                                                                                                                               |
| 188 |    610.657773 |    222.454238 | Scott Hartman                                                                                                                                                   |
| 189 |    994.319659 |     84.354422 | Gareth Monger                                                                                                                                                   |
| 190 |    784.731659 |    155.827431 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                   |
| 191 |    982.665941 |    717.507953 | Steven Coombs                                                                                                                                                   |
| 192 |    170.865245 |    244.158416 | Steven Traver                                                                                                                                                   |
| 193 |    944.401783 |    273.694306 | Gareth Monger                                                                                                                                                   |
| 194 |    965.542001 |     54.934179 | Gabriela Palomo-Munoz                                                                                                                                           |
| 195 |    192.974815 |    309.982763 | Hugo Gruson                                                                                                                                                     |
| 196 |    643.932188 |    521.273211 | Zimices                                                                                                                                                         |
| 197 |    782.384616 |    125.298396 | Beth Reinke                                                                                                                                                     |
| 198 |     36.698148 |    396.184611 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                           |
| 199 |    830.510772 |    483.325661 | Scott Hartman                                                                                                                                                   |
| 200 |    312.873730 |    641.189228 | Steven Traver                                                                                                                                                   |
| 201 |    253.558569 |    210.504113 | www.studiospectre.com                                                                                                                                           |
| 202 |    777.842453 |    280.447968 | 于川云                                                                                                                                                             |
| 203 |    828.328294 |    131.598786 | NA                                                                                                                                                              |
| 204 |    533.834783 |    602.965125 | Gabriela Palomo-Munoz                                                                                                                                           |
| 205 |    973.386698 |     82.787342 | Rebecca Groom                                                                                                                                                   |
| 206 |    465.662185 |     89.046160 | Prathyush Thomas                                                                                                                                                |
| 207 |    109.244377 |    490.990016 | Tyler Greenfield                                                                                                                                                |
| 208 |    632.311664 |    450.981436 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                        |
| 209 |    142.433707 |    361.520413 | Andy Wilson                                                                                                                                                     |
| 210 |    802.929217 |    572.833234 | Zimices                                                                                                                                                         |
| 211 |     64.986167 |    586.526784 | Jonathan Wells                                                                                                                                                  |
| 212 |    360.094419 |    108.861892 | Tracy A. Heath                                                                                                                                                  |
| 213 |    943.000126 |    629.862970 | Christoph Schomburg                                                                                                                                             |
| 214 |    754.476423 |     96.688973 | Chris huh                                                                                                                                                       |
| 215 |    526.634968 |    428.375460 | Ignacio Contreras                                                                                                                                               |
| 216 |     99.127787 |    752.018539 | Mathieu Pélissié                                                                                                                                                |
| 217 |    679.320624 |    456.385812 | Margot Michaud                                                                                                                                                  |
| 218 |    381.699227 |    771.931477 | Mason McNair                                                                                                                                                    |
| 219 |     44.510579 |    161.788227 | Ferran Sayol                                                                                                                                                    |
| 220 |    739.426961 |    540.761010 | Milton Tan                                                                                                                                                      |
| 221 |    741.133869 |    376.822460 | Kanchi Nanjo                                                                                                                                                    |
| 222 |    248.479816 |    255.086750 | Joanna Wolfe                                                                                                                                                    |
| 223 |    647.244432 |    639.533477 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                      |
| 224 |     57.773023 |    465.191309 | Kailah Thorn & Mark Hutchinson                                                                                                                                  |
| 225 |    479.678080 |    180.736319 | Matt Crook                                                                                                                                                      |
| 226 |    283.500816 |    417.104514 | NA                                                                                                                                                              |
| 227 |     89.455085 |    631.372728 | Xvazquez (vectorized by William Gearty)                                                                                                                         |
| 228 |    811.039480 |    628.786018 | Sean McCann                                                                                                                                                     |
| 229 |     46.020770 |    652.054697 | Steven Traver                                                                                                                                                   |
| 230 |    871.714820 |    234.542782 | T. Michael Keesey                                                                                                                                               |
| 231 |    722.926229 |    418.311036 | Zachary Quigley                                                                                                                                                 |
| 232 |    903.018334 |    371.597661 | Juan Carlos Jerí                                                                                                                                                |
| 233 |    946.894548 |    567.107850 | Jagged Fang Designs                                                                                                                                             |
| 234 |     79.732833 |    188.116439 | Roberto Díaz Sibaja                                                                                                                                             |
| 235 |     97.759905 |    600.100074 | Gabriela Palomo-Munoz                                                                                                                                           |
| 236 |    524.659990 |    397.194318 | Matt Crook                                                                                                                                                      |
| 237 |    935.712934 |     76.923934 | Matt Crook                                                                                                                                                      |
| 238 |    341.594790 |     32.014772 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 239 |    278.775234 |     79.071917 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                   |
| 240 |    404.003153 |    623.046744 | Markus A. Grohme                                                                                                                                                |
| 241 |    454.264261 |     24.241701 | Gabriela Palomo-Munoz                                                                                                                                           |
| 242 |   1005.388453 |    387.993471 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                   |
| 243 |    638.870436 |    657.513068 | Markus A. Grohme                                                                                                                                                |
| 244 |    589.057406 |    255.925013 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 245 |    365.151408 |    677.254822 | NA                                                                                                                                                              |
| 246 |    489.311513 |    538.539296 | Chris Jennings (Risiatto)                                                                                                                                       |
| 247 |     76.462099 |    243.185203 | David Orr                                                                                                                                                       |
| 248 |     37.133935 |    503.935169 | Kamil S. Jaron                                                                                                                                                  |
| 249 |    882.166520 |     95.978142 | Chris huh                                                                                                                                                       |
| 250 |    413.421300 |     21.833025 | Steven Traver                                                                                                                                                   |
| 251 |    110.539143 |    738.850811 | Chris huh                                                                                                                                                       |
| 252 |    217.926545 |     74.962581 | Zimices                                                                                                                                                         |
| 253 |    820.526314 |    298.587511 | Melissa Broussard                                                                                                                                               |
| 254 |    439.664611 |    791.755315 | Steven Traver                                                                                                                                                   |
| 255 |    697.460581 |    708.355703 | Nobu Tamura                                                                                                                                                     |
| 256 |    650.091260 |    583.161595 | Sarah Werning                                                                                                                                                   |
| 257 |    329.349909 |    652.646798 | Meliponicultor Itaymbere                                                                                                                                        |
| 258 |    706.661223 |    685.345425 | Steven Traver                                                                                                                                                   |
| 259 |    849.633698 |    475.614286 | T. Michael Keesey                                                                                                                                               |
| 260 |    691.810567 |    731.235823 | Lukasiniho                                                                                                                                                      |
| 261 |    568.736227 |    206.693163 | Jagged Fang Designs                                                                                                                                             |
| 262 |    366.992234 |     16.323984 | Tasman Dixon                                                                                                                                                    |
| 263 |    212.490634 |    587.996329 | Nobu Tamura                                                                                                                                                     |
| 264 |    813.078131 |    794.647267 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                |
| 265 |     11.712340 |    450.596356 | NA                                                                                                                                                              |
| 266 |    395.199181 |    315.969896 | DW Bapst (modified from Bulman, 1970)                                                                                                                           |
| 267 |     50.538754 |    140.827120 | Matt Martyniuk (modified by Serenchia)                                                                                                                          |
| 268 |   1015.549523 |    592.230447 | Jack Mayer Wood                                                                                                                                                 |
| 269 |    602.088098 |     29.330931 | Tyler Greenfield                                                                                                                                                |
| 270 |     45.464075 |    530.737360 | S.Martini                                                                                                                                                       |
| 271 |    640.372297 |    323.888706 | Noah Schlottman                                                                                                                                                 |
| 272 |    634.627660 |    416.244502 | Steven Traver                                                                                                                                                   |
| 273 |    258.601450 |    399.825439 | Michelle Site                                                                                                                                                   |
| 274 |    372.495114 |      5.572257 | Matt Crook                                                                                                                                                      |
| 275 |    160.472728 |    457.255549 | Scott Hartman                                                                                                                                                   |
| 276 |    839.735805 |    343.591095 | T. Michael Keesey (after James & al.)                                                                                                                           |
| 277 |    790.044514 |    535.023275 | Christoph Schomburg                                                                                                                                             |
| 278 |    178.779346 |     51.775362 | Steven Traver                                                                                                                                                   |
| 279 |     93.092391 |    562.312250 | T. Michael Keesey (after James & al.)                                                                                                                           |
| 280 |     53.722817 |    565.988149 | Chris huh                                                                                                                                                       |
| 281 |    170.274494 |    539.702556 | Sarah Werning                                                                                                                                                   |
| 282 |   1005.299611 |     75.112581 | NA                                                                                                                                                              |
| 283 |    881.549757 |    752.966119 | Tasman Dixon                                                                                                                                                    |
| 284 |    809.693194 |    376.117911 | Jon M Laurent                                                                                                                                                   |
| 285 |    926.243091 |     87.726275 | Zimices                                                                                                                                                         |
| 286 |    964.619947 |    405.936862 | Markus A. Grohme                                                                                                                                                |
| 287 |   1007.014377 |    323.211456 | Matt Crook                                                                                                                                                      |
| 288 |    278.297565 |    266.165251 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 289 |    256.681597 |    119.176783 | Gareth Monger                                                                                                                                                   |
| 290 |    462.754437 |    398.784185 | Noah Schlottman                                                                                                                                                 |
| 291 |    791.699547 |    450.044296 | Matus Valach                                                                                                                                                    |
| 292 |    621.503562 |    337.855416 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 293 |    456.048039 |    114.422525 | Ferran Sayol                                                                                                                                                    |
| 294 |    688.688753 |    244.154640 | Mike Hanson                                                                                                                                                     |
| 295 |    973.937160 |    539.636207 | Armin Reindl                                                                                                                                                    |
| 296 |    853.592115 |    400.723410 | Emily Willoughby                                                                                                                                                |
| 297 |    310.292013 |    139.029265 | Jagged Fang Designs                                                                                                                                             |
| 298 |     60.093536 |     82.602101 | Andy Wilson                                                                                                                                                     |
| 299 |    133.863961 |    101.497116 | Armin Reindl                                                                                                                                                    |
| 300 |    709.386149 |    792.927710 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                     |
| 301 |    616.377834 |    397.253791 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                           |
| 302 |    511.171574 |    454.824445 | Zimices                                                                                                                                                         |
| 303 |    525.022044 |    469.051198 | Steven Traver                                                                                                                                                   |
| 304 |    775.104459 |    323.135878 | Ferran Sayol                                                                                                                                                    |
| 305 |    417.133060 |    790.738733 | Andy Wilson                                                                                                                                                     |
| 306 |    594.762052 |    620.259911 | Ignacio Contreras                                                                                                                                               |
| 307 |    647.357763 |    312.825695 | Noah Schlottman, photo from Moorea Biocode                                                                                                                      |
| 308 |    554.713113 |    171.093109 | Manabu Bessho-Uehara                                                                                                                                            |
| 309 |    843.124725 |    297.711790 | Scott Hartman                                                                                                                                                   |
| 310 |    677.092754 |    480.421888 | Gabriela Palomo-Munoz                                                                                                                                           |
| 311 |    773.739429 |    559.036136 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 312 |    618.524943 |    408.000564 | Mykle Hoban                                                                                                                                                     |
| 313 |    905.543396 |    310.821725 | Konsta Happonen                                                                                                                                                 |
| 314 |    274.098218 |    734.905782 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 315 |   1007.488563 |    581.839981 | T. Michael Keesey                                                                                                                                               |
| 316 |    776.159334 |    446.432878 | Chris huh                                                                                                                                                       |
| 317 |    446.759055 |    373.211444 | Matt Crook                                                                                                                                                      |
| 318 |    437.049242 |    416.908149 | \[unknown\]                                                                                                                                                     |
| 319 |    661.880902 |    545.307477 | Scott Hartman                                                                                                                                                   |
| 320 |    253.955969 |    179.713145 | Rebecca Groom                                                                                                                                                   |
| 321 |    775.483178 |    290.960326 | Heinrich Harder (vectorized by William Gearty)                                                                                                                  |
| 322 |    997.090903 |    612.709229 | Roberto Díaz Sibaja                                                                                                                                             |
| 323 |    204.688460 |     72.936905 | Jake Warner                                                                                                                                                     |
| 324 |    787.914684 |    196.959085 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 325 |    430.622098 |    116.391165 | Carlos Cano-Barbacil                                                                                                                                            |
| 326 |    540.969010 |    166.355665 | Markus A. Grohme                                                                                                                                                |
| 327 |    745.754777 |     82.026660 | Gareth Monger                                                                                                                                                   |
| 328 |    531.893866 |    185.787820 | Jagged Fang Designs                                                                                                                                             |
| 329 |    312.452170 |    218.635328 | Roberto Diaz Sibaja, based on Domser                                                                                                                            |
| 330 |    243.449687 |    232.697443 | Matt Crook                                                                                                                                                      |
| 331 |    639.769016 |    397.717599 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                   |
| 332 |     11.620889 |    131.361462 | Smith609 and T. Michael Keesey                                                                                                                                  |
| 333 |    819.507423 |    336.646131 | Felix Vaux                                                                                                                                                      |
| 334 |    381.552643 |    617.667477 | Sarah Werning                                                                                                                                                   |
| 335 |     25.805169 |    694.247238 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                        |
| 336 |    187.351065 |    714.063157 | T. Michael Keesey                                                                                                                                               |
| 337 |    480.068352 |    376.860845 | Scott Hartman                                                                                                                                                   |
| 338 |    324.465344 |    312.375095 | NA                                                                                                                                                              |
| 339 |    555.044003 |     75.308356 | Gareth Monger                                                                                                                                                   |
| 340 |    228.159163 |    596.120210 | Ferran Sayol                                                                                                                                                    |
| 341 |    197.452419 |      8.201180 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                |
| 342 |     69.934141 |    644.018506 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                     |
| 343 |    807.954273 |    469.434239 | Jagged Fang Designs                                                                                                                                             |
| 344 |   1008.819843 |    521.368216 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                  |
| 345 |    208.223290 |    550.047545 | Scott Reid                                                                                                                                                      |
| 346 |    347.932242 |    316.948753 | Inessa Voet                                                                                                                                                     |
| 347 |    904.543009 |      4.398104 | Mette Aumala                                                                                                                                                    |
| 348 |     68.953846 |     94.170641 | Lukasiniho                                                                                                                                                      |
| 349 |    875.520927 |    339.794611 | Abraão Leite                                                                                                                                                    |
| 350 |    913.337312 |    133.422245 | CNZdenek                                                                                                                                                        |
| 351 |     11.773466 |    611.455377 | Michael Scroggie                                                                                                                                                |
| 352 |    590.168286 |    221.253379 | Mathieu Pélissié                                                                                                                                                |
| 353 |    957.760137 |    424.627608 | Dmitry Bogdanov                                                                                                                                                 |
| 354 |    411.593140 |    429.392620 | Armin Reindl                                                                                                                                                    |
| 355 |    594.651475 |    355.593279 | Zimices                                                                                                                                                         |
| 356 |    149.760189 |    525.903423 | Matt Crook                                                                                                                                                      |
| 357 |     78.363286 |    292.634262 | Tyler Greenfield                                                                                                                                                |
| 358 |    544.352718 |    159.011688 | Ramona J Heim                                                                                                                                                   |
| 359 |     89.287873 |    645.568039 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                |
| 360 |    108.426912 |    578.232819 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                              |
| 361 |    973.248637 |    556.989373 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                          |
| 362 |    501.877622 |     99.912541 | Yusan Yang                                                                                                                                                      |
| 363 |    360.980571 |    301.965581 | Markus A. Grohme                                                                                                                                                |
| 364 |    354.072076 |    610.605803 | Michael Scroggie                                                                                                                                                |
| 365 |    574.832207 |    680.105409 | Claus Rebler                                                                                                                                                    |
| 366 |    757.043524 |     50.800361 | Scott Hartman                                                                                                                                                   |
| 367 |    677.092154 |    343.664994 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                  |
| 368 |    111.696408 |    189.622996 | Milton Tan                                                                                                                                                      |
| 369 |    118.787142 |    524.982144 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 370 |    543.731982 |    403.283453 | \[unknown\]                                                                                                                                                     |
| 371 |    271.465508 |    133.304518 | Matt Crook                                                                                                                                                      |
| 372 |    420.687315 |    779.718753 | T. Michael Keesey                                                                                                                                               |
| 373 |    555.208123 |     38.689841 | NA                                                                                                                                                              |
| 374 |    765.681574 |     11.905078 | Yusan Yang                                                                                                                                                      |
| 375 |    575.585041 |    272.709422 | Filip em                                                                                                                                                        |
| 376 |    880.872728 |    164.400596 | NA                                                                                                                                                              |
| 377 |    310.510597 |     94.825784 | Margot Michaud                                                                                                                                                  |
| 378 |    184.189856 |    448.410905 | Zimices                                                                                                                                                         |
| 379 |    607.821565 |    268.500820 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 380 |    212.724963 |     55.998086 | Katie S. Collins                                                                                                                                                |
| 381 |    334.492691 |    762.629813 | Steven Traver                                                                                                                                                   |
| 382 |    819.577058 |    315.671612 | NA                                                                                                                                                              |
| 383 |    218.869242 |      6.255585 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                    |
| 384 |    772.486194 |    215.751472 | Margot Michaud                                                                                                                                                  |
| 385 |    571.616738 |    357.755358 | Chris huh                                                                                                                                                       |
| 386 |    515.020621 |     29.104744 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                     |
| 387 |    175.139336 |    656.666773 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 388 |     32.855887 |    716.055530 | Matt Crook                                                                                                                                                      |
| 389 |     29.662091 |    476.707127 | Andy Wilson                                                                                                                                                     |
| 390 |    669.474533 |    648.488651 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                  |
| 391 |    965.291444 |    311.663851 | Steven Traver                                                                                                                                                   |
| 392 |    396.970201 |    487.769386 | Noah Schlottman                                                                                                                                                 |
| 393 |    409.852237 |    240.036278 | Markus A. Grohme                                                                                                                                                |
| 394 |    685.466433 |     57.043511 | Skye McDavid                                                                                                                                                    |
| 395 |    836.515176 |     45.812818 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 396 |    296.035186 |    106.597701 | Zimices                                                                                                                                                         |
| 397 |    316.176613 |    236.070025 | Matt Crook                                                                                                                                                      |
| 398 |    506.432286 |    584.691315 | Chris Hay                                                                                                                                                       |
| 399 |   1011.702435 |    467.201910 | Kristina Gagalova                                                                                                                                               |
| 400 |    965.153229 |    729.576651 | Margot Michaud                                                                                                                                                  |
| 401 |    695.023285 |    361.395061 | S.Martini                                                                                                                                                       |
| 402 |    732.734997 |    688.789337 | Noah Schlottman, photo from Casey Dunn                                                                                                                          |
| 403 |     95.473628 |    229.203264 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 404 |    804.599629 |    558.263133 | T. Michael Keesey                                                                                                                                               |
| 405 |    804.359627 |    193.069262 | Andrew A. Farke                                                                                                                                                 |
| 406 |     20.184471 |     18.408586 | Gareth Monger                                                                                                                                                   |
| 407 |    277.759182 |    607.153785 | Michelle Site                                                                                                                                                   |
| 408 |    768.365192 |    575.405747 | Matt Crook                                                                                                                                                      |
| 409 |    195.162123 |    662.034829 | Margot Michaud                                                                                                                                                  |
| 410 |    714.741644 |     86.867659 | Sarah Werning                                                                                                                                                   |
| 411 |    400.725582 |    119.869452 | Kent Sorgon                                                                                                                                                     |
| 412 |    217.981069 |    679.831567 | Gabriela Palomo-Munoz                                                                                                                                           |
| 413 |    117.745523 |    183.266995 | Jagged Fang Designs                                                                                                                                             |
| 414 |    459.890313 |    351.413819 | Matt Martyniuk (modified by Serenchia)                                                                                                                          |
| 415 |    643.120050 |    226.930609 | Jagged Fang Designs                                                                                                                                             |
| 416 |    962.551130 |    579.883094 | Oscar Sanisidro                                                                                                                                                 |
| 417 |    138.108176 |    182.918416 | C. Camilo Julián-Caballero                                                                                                                                      |
| 418 |    262.547546 |    679.142735 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                |
| 419 |   1014.120908 |    551.421446 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                |
| 420 |     45.761787 |    585.583011 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                           |
| 421 |    378.980154 |    104.516005 | Tony Ayling                                                                                                                                                     |
| 422 |    394.094607 |    522.949218 | Rene Martin                                                                                                                                                     |
| 423 |    528.801220 |    438.371301 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                         |
| 424 |   1012.250384 |      9.442405 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 425 |    653.418842 |    437.602059 | Margot Michaud                                                                                                                                                  |
| 426 |     51.945625 |    282.224464 | Steven Blackwood                                                                                                                                                |
| 427 |    208.923583 |    302.608411 | Eyal Bartov                                                                                                                                                     |
| 428 |    454.496581 |    204.895839 | Margot Michaud                                                                                                                                                  |
| 429 |    937.434832 |    544.252735 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 430 |     36.774681 |     22.774544 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 431 |    504.569757 |    420.191944 | Chris huh                                                                                                                                                       |
| 432 |    789.382422 |    391.879255 | Iain Reid                                                                                                                                                       |
| 433 |    778.552789 |    181.444090 | Ryan Cupo                                                                                                                                                       |
| 434 |    659.056282 |    525.549731 | Jagged Fang Designs                                                                                                                                             |
| 435 |    566.992257 |    791.245043 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                 |
| 436 |     60.441205 |    634.437921 | Chris huh                                                                                                                                                       |
| 437 |    451.294358 |    738.413657 | Gabriela Palomo-Munoz                                                                                                                                           |
| 438 |    141.118468 |    206.259464 | Gareth Monger                                                                                                                                                   |
| 439 |    905.053220 |    720.461939 | NA                                                                                                                                                              |
| 440 |    819.075866 |    121.107362 | Chris huh                                                                                                                                                       |
| 441 |    982.291200 |    572.727161 | S.Martini                                                                                                                                                       |
| 442 |      9.855906 |    142.679444 | Gabriela Palomo-Munoz                                                                                                                                           |
| 443 |    801.626970 |    302.896581 | Steven Traver                                                                                                                                                   |
| 444 |    589.789767 |    662.992703 | T. Michael Keesey (after Ponomarenko)                                                                                                                           |
| 445 |    398.638631 |    771.126414 | Matt Crook                                                                                                                                                      |
| 446 |    652.032913 |    451.364217 | Tauana J. Cunha                                                                                                                                                 |
| 447 |   1003.613180 |    723.371522 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                           |
| 448 |    611.568482 |    213.250020 | Gabriela Palomo-Munoz                                                                                                                                           |
| 449 |    434.530296 |    654.078213 | NA                                                                                                                                                              |
| 450 |    637.313982 |    778.662215 | L. Shyamal                                                                                                                                                      |
| 451 |    797.343843 |    117.391615 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                           |
| 452 |    669.812234 |    246.193514 | Matt Crook                                                                                                                                                      |
| 453 |     53.639366 |      6.862577 | Steven Traver                                                                                                                                                   |
| 454 |     63.099593 |    348.144432 | V. Deepak                                                                                                                                                       |
| 455 |     67.247680 |     57.669510 | Zimices                                                                                                                                                         |
| 456 |    196.415445 |    359.722756 | Zimices                                                                                                                                                         |
| 457 |    545.132746 |    520.151781 | Margot Michaud                                                                                                                                                  |
| 458 |    867.435837 |    381.803849 | Tasman Dixon                                                                                                                                                    |
| 459 |    440.240821 |     85.702899 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                   |
| 460 |    907.719600 |    699.471138 | Tasman Dixon                                                                                                                                                    |
| 461 |    776.015782 |    601.920499 | Gabriela Palomo-Munoz                                                                                                                                           |
| 462 |    523.667786 |    153.832504 | Sharon Wegner-Larsen                                                                                                                                            |
| 463 |    352.807127 |    721.418863 | Jaime Headden                                                                                                                                                   |
| 464 |   1005.905579 |    626.304080 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                              |
| 465 |    965.425358 |    294.817818 | Matt Crook                                                                                                                                                      |
| 466 |    164.525442 |    486.153451 | Collin Gross                                                                                                                                                    |
| 467 |    854.744170 |    501.586790 | Zimices                                                                                                                                                         |
| 468 |    357.431445 |    762.501819 | Margot Michaud                                                                                                                                                  |
| 469 |    423.728716 |    426.753254 | Noah Schlottman                                                                                                                                                 |
| 470 |    888.183950 |    417.403915 | Margot Michaud                                                                                                                                                  |
| 471 |    840.846768 |    716.763629 | Gabriela Palomo-Munoz                                                                                                                                           |
| 472 |    817.686819 |    251.315028 | Peileppe                                                                                                                                                        |
| 473 |    378.846901 |    391.542918 | Carlos Cano-Barbacil                                                                                                                                            |
| 474 |    666.110575 |    334.521902 | Katie S. Collins                                                                                                                                                |
| 475 |    545.856712 |     70.448481 | Fernando Carezzano                                                                                                                                              |
| 476 |    227.728378 |    215.383368 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                 |
| 477 |    726.376432 |     20.576197 | Zimices                                                                                                                                                         |
| 478 |    968.586863 |    377.590303 | Gareth Monger                                                                                                                                                   |
| 479 |    879.917833 |    144.285548 | Chris huh                                                                                                                                                       |
| 480 |    266.288796 |    369.518242 | Mathieu Pélissié                                                                                                                                                |
| 481 |    161.884319 |     86.273304 | Gareth Monger                                                                                                                                                   |
| 482 |    828.380516 |    642.936544 | NA                                                                                                                                                              |
| 483 |    877.859322 |    479.700390 | Matt Crook                                                                                                                                                      |
| 484 |     89.890488 |    614.264839 | Margot Michaud                                                                                                                                                  |
| 485 |    124.478491 |     37.161071 | Zimices                                                                                                                                                         |
| 486 |    881.385160 |    407.680212 | zoosnow                                                                                                                                                         |
| 487 |    424.773552 |    526.857478 | Jagged Fang Designs                                                                                                                                             |
| 488 |    142.609888 |      9.924378 | Tracy A. Heath                                                                                                                                                  |
| 489 |    871.704512 |    682.875407 | Tasman Dixon                                                                                                                                                    |
| 490 |    244.049640 |     17.352145 | Noah Schlottman, photo by Carol Cummings                                                                                                                        |
| 491 |    219.625453 |    228.728464 | Jaime Headden                                                                                                                                                   |
| 492 |    231.089863 |    307.767009 | Skye McDavid                                                                                                                                                    |
| 493 |    827.668648 |    739.148275 | Ferran Sayol                                                                                                                                                    |
| 494 |     85.253707 |    320.474650 | Gareth Monger                                                                                                                                                   |
| 495 |    169.153310 |    680.453607 | Matt Crook                                                                                                                                                      |
| 496 |    993.204911 |    456.949879 | Dean Schnabel                                                                                                                                                   |
| 497 |    335.537133 |    292.518186 | Xavier Giroux-Bougard                                                                                                                                           |
| 498 |    636.598956 |    236.757954 | Tambja (vectorized by T. Michael Keesey)                                                                                                                        |
| 499 |    741.808531 |    201.312705 | Ferran Sayol                                                                                                                                                    |
| 500 |    162.221882 |    559.671362 | Christoph Schomburg                                                                                                                                             |
| 501 |    202.830837 |    225.891803 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 502 |    565.687641 |    764.668057 | Tasman Dixon                                                                                                                                                    |
| 503 |    759.830519 |    456.958221 | Andrew A. Farke                                                                                                                                                 |
| 504 |     33.932910 |    389.156356 | Cesar Julian                                                                                                                                                    |
| 505 |    643.933974 |    544.602610 | Gareth Monger                                                                                                                                                   |
| 506 |    794.375621 |    163.822633 | Chris huh                                                                                                                                                       |
| 507 |    664.222669 |    491.577733 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                       |
| 508 |    608.888190 |     66.447947 | Alex Slavenko                                                                                                                                                   |
| 509 |    750.308097 |     61.720331 | Jose Carlos Arenas-Monroy                                                                                                                                       |
| 510 |    588.976576 |     30.336682 | Zimices / Julián Bayona                                                                                                                                         |
| 511 |    630.005837 |    743.646786 | Kamil S. Jaron                                                                                                                                                  |
| 512 |    340.416434 |     99.142869 | xgirouxb                                                                                                                                                        |
| 513 |    682.412001 |    757.200310 | Gareth Monger                                                                                                                                                   |
| 514 |    648.312190 |    589.638193 | Roberto Díaz Sibaja                                                                                                                                             |
| 515 |     31.823213 |     91.199705 | Ieuan Jones                                                                                                                                                     |
| 516 |   1015.551448 |    639.521176 | Andy Wilson                                                                                                                                                     |
| 517 |    968.380267 |    392.625380 | Margot Michaud                                                                                                                                                  |
| 518 |    537.045656 |     82.470177 | Jaime Headden                                                                                                                                                   |
| 519 |    368.042780 |    512.063823 | Kamil S. Jaron                                                                                                                                                  |
| 520 |     62.074199 |    114.584259 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                |
| 521 |     52.597516 |    188.143232 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                   |
| 522 |    864.997754 |    792.643127 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                     |
| 523 |    521.954521 |    168.559418 | Zimices                                                                                                                                                         |
| 524 |    472.877213 |    792.470630 | Pete Buchholz                                                                                                                                                   |
| 525 |    689.773719 |    656.416163 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                        |
| 526 |    429.493811 |    123.513002 | Jagged Fang Designs                                                                                                                                             |
| 527 |    566.618556 |    548.272223 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                      |
| 528 |    494.924128 |    561.300201 | Roderic Page and Lois Page                                                                                                                                      |
| 529 |    112.255314 |    763.164024 | T. Michael Keesey                                                                                                                                               |
| 530 |    879.836341 |    253.037639 | Manabu Bessho-Uehara                                                                                                                                            |
| 531 |    243.853298 |    488.628920 | Collin Gross                                                                                                                                                    |
| 532 |    492.139448 |    430.625297 | Jaime Headden                                                                                                                                                   |
| 533 |    945.228118 |     10.775081 | NA                                                                                                                                                              |
| 534 |    290.877547 |    397.359696 | Emily Willoughby                                                                                                                                                |
| 535 |    996.529064 |      5.184056 | Chris huh                                                                                                                                                       |
| 536 |    674.656853 |    768.836840 | Terpsichores                                                                                                                                                    |
| 537 |    826.584129 |    462.204932 | Michelle Site                                                                                                                                                   |
| 538 |    738.881401 |    438.447674 | Matt Crook                                                                                                                                                      |
| 539 |    679.572186 |    739.518293 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                   |
| 540 |    752.717006 |    171.796464 | NA                                                                                                                                                              |
| 541 |    521.955684 |    532.558953 | Tasman Dixon                                                                                                                                                    |
| 542 |      3.970771 |    407.612264 | Steven Traver                                                                                                                                                   |
| 543 |    270.144969 |      8.146763 | Matt Crook                                                                                                                                                      |
| 544 |    290.385094 |     83.951673 | Tasman Dixon                                                                                                                                                    |
| 545 |    370.476679 |    747.433873 | T. Michael Keesey and Tanetahi                                                                                                                                  |
| 546 |    484.733455 |     15.579686 | NA                                                                                                                                                              |
| 547 |    304.706074 |     69.054016 | Rebecca Groom                                                                                                                                                   |
| 548 |    118.907993 |    710.777234 | Matt Crook                                                                                                                                                      |
| 549 |    557.822640 |    757.362129 | Chris huh                                                                                                                                                       |
| 550 |    728.857572 |    365.111021 | Birgit Lang                                                                                                                                                     |
| 551 |    834.602451 |    517.358219 | T. Michael Keesey                                                                                                                                               |
| 552 |     55.058139 |    418.861042 | Tracy A. Heath                                                                                                                                                  |
| 553 |    186.940477 |    214.253846 | Steven Traver                                                                                                                                                   |
| 554 |    130.504789 |    561.617420 | Katie S. Collins                                                                                                                                                |
| 555 |    180.879737 |     74.694486 | C. Camilo Julián-Caballero                                                                                                                                      |
| 556 |    944.585835 |    394.454393 | Smokeybjb                                                                                                                                                       |
| 557 |    826.700621 |    783.488288 | Markus A. Grohme                                                                                                                                                |
| 558 |    371.879263 |    317.935297 | Scott Hartman                                                                                                                                                   |
| 559 |    122.561327 |    368.269347 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                        |
| 560 |    977.049130 |    138.690843 | NA                                                                                                                                                              |
| 561 |    214.740844 |    610.385459 | Davidson Sodré                                                                                                                                                  |
| 562 |    842.601780 |    561.285673 | T. Michael Keesey                                                                                                                                               |
| 563 |    800.617432 |    130.508660 | Christoph Schomburg                                                                                                                                             |
| 564 |    344.025403 |    421.982608 | Gareth Monger                                                                                                                                                   |
| 565 |    623.590127 |    314.781874 | Erika Schumacher                                                                                                                                                |
| 566 |     28.248596 |    790.363006 | Scott Hartman                                                                                                                                                   |
| 567 |    297.307863 |    355.009451 | NA                                                                                                                                                              |
| 568 |    686.984308 |     42.617640 | Margot Michaud                                                                                                                                                  |
| 569 |    795.208045 |    377.826891 | Sergio A. Muñoz-Gómez                                                                                                                                           |
| 570 |    646.790063 |    617.682622 | Zimices                                                                                                                                                         |
| 571 |    507.060073 |     78.654753 | Matt Crook                                                                                                                                                      |
| 572 |     38.140810 |    609.435576 | Gabriela Palomo-Munoz                                                                                                                                           |
| 573 |     75.344296 |    426.825428 | Noah Schlottman, photo from Casey Dunn                                                                                                                          |
| 574 |    601.760176 |    797.832778 | Ferran Sayol                                                                                                                                                    |
| 575 |    590.178137 |    719.038438 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                |
| 576 |    144.461932 |     86.399107 | Matt Crook                                                                                                                                                      |
| 577 |    389.101313 |    502.716875 | Oscar Sanisidro                                                                                                                                                 |
| 578 |   1002.222264 |    111.848769 | Yan Wong                                                                                                                                                        |
| 579 |    817.606596 |    562.672853 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                |
| 580 |    584.702623 |      9.491715 | Steven Traver                                                                                                                                                   |
| 581 |    191.081887 |    730.679481 | Gareth Monger                                                                                                                                                   |
| 582 |    436.940088 |     26.869538 | Steven Traver                                                                                                                                                   |
| 583 |    244.448550 |    584.641315 | T. Michael Keesey                                                                                                                                               |
| 584 |    253.595419 |    313.429712 | Markus A. Grohme                                                                                                                                                |
| 585 |    676.707888 |    208.123343 | Zimices                                                                                                                                                         |
| 586 |    997.948456 |     24.803242 | Scott Hartman                                                                                                                                                   |
| 587 |    524.793365 |    336.577605 | Matt Crook                                                                                                                                                      |
| 588 |    588.837878 |    640.095742 | Matt Crook                                                                                                                                                      |
| 589 |    356.549466 |    289.649212 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                 |
| 590 |   1013.741352 |    788.938613 | Daniel Stadtmauer                                                                                                                                               |
| 591 |    930.320134 |    312.030303 | Gabriela Palomo-Munoz                                                                                                                                           |
| 592 |    667.266584 |    291.567022 | zoosnow                                                                                                                                                         |
| 593 |      3.111764 |    386.623516 | Kanchi Nanjo                                                                                                                                                    |
| 594 |    410.866053 |    137.699933 | NA                                                                                                                                                              |
| 595 |    255.675306 |    687.308325 | Gareth Monger                                                                                                                                                   |
| 596 |    669.780207 |    178.099238 | Sharon Wegner-Larsen                                                                                                                                            |
| 597 |    938.307394 |    703.119817 | NA                                                                                                                                                              |
| 598 |     94.196520 |    249.513582 | Tasman Dixon                                                                                                                                                    |
| 599 |    409.714104 |     92.432437 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                 |
| 600 |    455.095501 |    415.517344 | Manabu Sakamoto                                                                                                                                                 |
| 601 |    810.192785 |     36.088160 | Tyler Greenfield and Dean Schnabel                                                                                                                              |
| 602 |    456.333487 |    707.775795 | Tasman Dixon                                                                                                                                                    |
| 603 |    107.080823 |    653.071693 | Andy Wilson                                                                                                                                                     |
| 604 |    759.642541 |    339.040958 | NA                                                                                                                                                              |
| 605 |    980.485692 |    734.345660 | Gareth Monger                                                                                                                                                   |
| 606 |    212.357952 |     30.818161 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 607 |    511.634851 |    132.098700 | Zimices                                                                                                                                                         |
| 608 |    489.778045 |     91.598123 | Riccardo Percudani                                                                                                                                              |
| 609 |    751.669771 |    295.520384 | Matt Martyniuk (modified by Serenchia)                                                                                                                          |
| 610 |    544.963364 |    143.314728 | Manabu Bessho-Uehara                                                                                                                                            |
| 611 |    746.697421 |    120.212999 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                  |
| 612 |    254.850086 |    381.539298 | Todd Marshall, vectorized by Zimices                                                                                                                            |
| 613 |   1014.452170 |     52.287017 | Steven Traver                                                                                                                                                   |
| 614 |    834.220137 |    373.520314 | Andy Wilson                                                                                                                                                     |
| 615 |    511.161302 |    594.563927 | Steven Traver                                                                                                                                                   |
| 616 |     74.310170 |    549.193108 | Sean McCann                                                                                                                                                     |
| 617 |    744.938133 |    186.167551 | Melissa Broussard                                                                                                                                               |
| 618 |    698.950222 |    785.818929 | Alexandra van der Geer                                                                                                                                          |
| 619 |    534.362083 |    652.565622 | Benjamint444                                                                                                                                                    |
| 620 |    615.954924 |    258.387664 | Tracy A. Heath                                                                                                                                                  |
| 621 |    952.286773 |     93.905309 | Margot Michaud                                                                                                                                                  |
| 622 |    800.611867 |     98.966692 | Becky Barnes                                                                                                                                                    |
| 623 |    630.364823 |     83.236195 | Felix Vaux                                                                                                                                                      |
| 624 |    390.205290 |    269.514115 | Matt Crook                                                                                                                                                      |
| 625 |    118.093028 |    558.933008 | Tracy A. Heath                                                                                                                                                  |
| 626 |    849.888399 |    388.338161 | Tasman Dixon                                                                                                                                                    |
| 627 |    422.189839 |    212.792490 | NA                                                                                                                                                              |
| 628 |    215.436734 |    353.528123 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                 |
| 629 |    623.087540 |    600.134233 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                       |
| 630 |    900.323509 |    730.302537 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                               |
| 631 |     16.215826 |    155.410769 | Margot Michaud                                                                                                                                                  |
| 632 |    418.944149 |    231.288815 | Margot Michaud                                                                                                                                                  |
| 633 |    197.228431 |    568.510312 | Sarah Werning                                                                                                                                                   |
| 634 |     34.024647 |    299.874955 | C. Camilo Julián-Caballero                                                                                                                                      |
| 635 |    379.562724 |    310.697965 | Scott Hartman                                                                                                                                                   |
| 636 |    141.925147 |    746.626888 | Shyamal                                                                                                                                                         |
| 637 |    117.443083 |    669.023424 | Chris huh                                                                                                                                                       |
| 638 |    231.036565 |     79.140360 | Michael Scroggie                                                                                                                                                |
| 639 |    408.200573 |    411.420500 | Yan Wong from illustration by Jules Richard (1907)                                                                                                              |
| 640 |    434.269087 |    674.587400 | Armin Reindl                                                                                                                                                    |
| 641 |    509.341068 |    326.489967 | Jonathan Wells                                                                                                                                                  |
| 642 |    826.496376 |    144.872528 | Steven Traver                                                                                                                                                   |
| 643 |     72.436936 |    228.489858 | Matt Crook                                                                                                                                                      |
| 644 |    590.543052 |    603.377838 | Matt Crook                                                                                                                                                      |
| 645 |    983.231987 |    546.137396 | Michael Scroggie                                                                                                                                                |
| 646 |     73.402956 |    260.838599 | Matt Crook                                                                                                                                                      |
| 647 |    347.724241 |    405.483674 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                               |
| 648 |    548.962984 |    571.888104 | Noah Schlottman, photo from Casey Dunn                                                                                                                          |
| 649 |    285.876237 |    153.701065 | Margot Michaud                                                                                                                                                  |
| 650 |    876.190257 |    724.104022 | Matt Crook                                                                                                                                                      |
| 651 |    689.725201 |    691.925923 | Michael Scroggie                                                                                                                                                |
| 652 |    773.591469 |     98.263137 | Ferran Sayol                                                                                                                                                    |
| 653 |     85.285884 |    216.485570 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                       |
| 654 |    217.973579 |    239.695578 | Matt Crook                                                                                                                                                      |
| 655 |    430.136727 |    301.057587 | Ferran Sayol                                                                                                                                                    |
| 656 |    539.613790 |    698.764966 | Gareth Monger                                                                                                                                                   |
| 657 |    703.858273 |    185.089929 | Collin Gross                                                                                                                                                    |
| 658 |    458.421113 |    655.721323 | Louis Ranjard                                                                                                                                                   |
| 659 |     86.172472 |    586.367199 | Zimices                                                                                                                                                         |
| 660 |    621.377397 |    543.903875 | Andy Wilson                                                                                                                                                     |
| 661 |    152.148641 |    713.546042 | Margot Michaud                                                                                                                                                  |
| 662 |    359.598776 |    389.278641 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                 |
| 663 |    894.290534 |     60.659082 | Gareth Monger                                                                                                                                                   |
| 664 |    334.632861 |     17.499433 | Armin Reindl                                                                                                                                                    |
| 665 |      7.765219 |    714.211928 | Michael Scroggie                                                                                                                                                |
| 666 |    917.264676 |    371.360738 | Zimices                                                                                                                                                         |
| 667 |    307.684283 |    278.457743 | Steven Traver                                                                                                                                                   |
| 668 |    854.330607 |    451.524536 | Rebecca Groom                                                                                                                                                   |
| 669 |    583.895810 |    287.873497 | Chris huh                                                                                                                                                       |
| 670 |    856.373064 |    739.293360 | Birgit Lang                                                                                                                                                     |
| 671 |    930.248764 |    580.907043 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
| 672 |    133.009450 |    540.474417 | Tasman Dixon                                                                                                                                                    |
| 673 |    800.703060 |    329.116849 | Zimices                                                                                                                                                         |
| 674 |    420.376763 |    485.572600 | Collin Gross                                                                                                                                                    |
| 675 |    208.741447 |    200.995238 | Matt Crook                                                                                                                                                      |
| 676 |    989.883783 |    101.581262 | C. Camilo Julián-Caballero                                                                                                                                      |
| 677 |    766.817455 |     63.289721 | Zimices                                                                                                                                                         |
| 678 |    102.712563 |    440.877119 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                          |
| 679 |    401.721716 |    295.066997 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                   |
| 680 |     61.305759 |    277.625809 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 681 |    339.100016 |    248.406577 | Margot Michaud                                                                                                                                                  |
| 682 |    188.111339 |    681.963901 | Steven Traver                                                                                                                                                   |
| 683 |    776.118888 |    206.568853 | Ferran Sayol                                                                                                                                                    |
| 684 |    175.019078 |    695.416626 | Steven Traver                                                                                                                                                   |
| 685 |    780.122864 |    139.032599 | Steven Traver                                                                                                                                                   |
| 686 |     27.768936 |    559.919014 | Tyler Greenfield                                                                                                                                                |
| 687 |    938.182569 |    283.439453 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                |
| 688 |    431.625125 |    360.625539 | Matt Crook                                                                                                                                                      |
| 689 |    215.310042 |    789.656009 | Tasman Dixon                                                                                                                                                    |
| 690 |    615.719350 |    181.863065 | Gareth Monger                                                                                                                                                   |
| 691 |    366.983223 |     86.907421 | NA                                                                                                                                                              |
| 692 |    484.133107 |    407.129218 | Emily Willoughby                                                                                                                                                |
| 693 |    242.731466 |    203.625079 | Gabriela Palomo-Munoz                                                                                                                                           |
| 694 |    330.520116 |    106.346692 | CNZdenek                                                                                                                                                        |
| 695 |    273.017652 |    723.746782 | Collin Gross                                                                                                                                                    |
| 696 |    578.954944 |     41.868005 | Zimices                                                                                                                                                         |
| 697 |    840.496532 |    371.421695 | Gareth Monger                                                                                                                                                   |
| 698 |     37.204164 |    632.333949 | Matt Crook                                                                                                                                                      |
| 699 |    347.058252 |    730.853983 | Becky Barnes                                                                                                                                                    |
| 700 |    586.969620 |    410.711846 | Zimices                                                                                                                                                         |
| 701 |     59.938905 |    203.300912 | Jagged Fang Designs                                                                                                                                             |
| 702 |    787.174949 |    578.557923 | Andy Wilson                                                                                                                                                     |
| 703 |      9.733580 |    667.707762 | Dinah Challen                                                                                                                                                   |
| 704 |    817.906039 |    389.355600 | Scott Hartman                                                                                                                                                   |
| 705 |    539.196441 |     95.482899 | Shyamal                                                                                                                                                         |
| 706 |    702.251239 |     90.876783 | Michele Tobias                                                                                                                                                  |
| 707 |    124.474632 |    531.952468 | C. Camilo Julián-Caballero                                                                                                                                      |
| 708 |    146.339558 |    196.067987 | Matt Crook                                                                                                                                                      |
| 709 |    531.134599 |    276.456981 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                               |
| 710 |    272.264756 |    302.392688 | Michelle Site                                                                                                                                                   |
| 711 |    327.554108 |    153.694042 | Abraão Leite                                                                                                                                                    |
| 712 |    153.660496 |    157.473572 | Kai R. Caspar                                                                                                                                                   |
| 713 |    999.179009 |    500.635208 | Gregor Bucher, Max Farnworth                                                                                                                                    |
| 714 |    998.622426 |    534.319396 | Craig Dylke                                                                                                                                                     |
| 715 |    113.909125 |     44.486402 | T. Michael Keesey                                                                                                                                               |
| 716 |    519.604452 |    579.603202 | Ferran Sayol                                                                                                                                                    |
| 717 |    248.016857 |    274.600018 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                 |
| 718 |    668.824029 |    384.604925 | Jagged Fang Designs                                                                                                                                             |
| 719 |    372.214626 |    406.346950 | James R. Spotila and Ray Chatterji                                                                                                                              |
| 720 |    235.342110 |    502.140858 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                 |
| 721 |    708.588991 |     57.011372 | Margot Michaud                                                                                                                                                  |
| 722 |    690.625382 |    224.207449 | Ferran Sayol                                                                                                                                                    |
| 723 |    542.494647 |    126.909857 | Zimices                                                                                                                                                         |
| 724 |    403.722562 |    212.805538 | Michelle Site                                                                                                                                                   |
| 725 |    406.277450 |      3.953439 | Jagged Fang Designs                                                                                                                                             |
| 726 |     47.298907 |    469.334474 | Darius Nau                                                                                                                                                      |
| 727 |    756.921453 |    271.487572 | NA                                                                                                                                                              |
| 728 |    984.935287 |    400.258968 | NA                                                                                                                                                              |
| 729 |    666.217196 |    445.319078 | Matt Crook                                                                                                                                                      |
| 730 |    809.141166 |    461.913291 | Alex Slavenko                                                                                                                                                   |
| 731 |    915.023498 |    580.399081 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                               |
| 732 |    711.642896 |     97.742540 | Andrew A. Farke                                                                                                                                                 |
| 733 |    926.465147 |    360.682940 | Gareth Monger                                                                                                                                                   |
| 734 |   1011.442732 |    289.520338 | NA                                                                                                                                                              |
| 735 |   1011.699504 |     91.725067 | Zimices                                                                                                                                                         |
| 736 |    887.379718 |    432.637000 | Matt Crook                                                                                                                                                      |
| 737 |    844.233912 |    316.071051 | Jagged Fang Designs                                                                                                                                             |
| 738 |    688.757213 |    791.571171 | Tauana J. Cunha                                                                                                                                                 |
| 739 |    953.907186 |     31.910777 | Manabu Bessho-Uehara                                                                                                                                            |
| 740 |      8.577823 |    496.777672 | Ferran Sayol                                                                                                                                                    |
| 741 |    587.195318 |    732.211337 | Noah Schlottman                                                                                                                                                 |
| 742 |    986.436804 |    316.902265 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 743 |    332.873332 |    188.812614 | NA                                                                                                                                                              |
| 744 |    379.572933 |     23.247439 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 745 |    467.610561 |    410.110255 | Mathieu Basille                                                                                                                                                 |
| 746 |      9.789022 |    785.664353 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                  |
| 747 |    943.149090 |     48.581367 | Gopal Murali                                                                                                                                                    |
| 748 |    861.933529 |    333.408676 | Margot Michaud                                                                                                                                                  |
| 749 |    264.378620 |    527.205974 | Gregor Bucher, Max Farnworth                                                                                                                                    |
| 750 |    240.093673 |    130.850398 | Andy Wilson                                                                                                                                                     |
| 751 |    150.165469 |    310.523897 | Gabriela Palomo-Munoz                                                                                                                                           |
| 752 |    539.996240 |    225.045772 | Markus A. Grohme                                                                                                                                                |
| 753 |    964.410696 |    103.171198 | Matt Crook                                                                                                                                                      |
| 754 |    986.511732 |    467.899306 | Ferran Sayol                                                                                                                                                    |
| 755 |     55.905285 |    237.037733 | Emily Willoughby                                                                                                                                                |
| 756 |    402.784003 |    667.337232 | Matt Crook                                                                                                                                                      |
| 757 |    556.946253 |    677.741075 | Gabriela Palomo-Munoz                                                                                                                                           |
| 758 |    951.475324 |    288.835856 | Nobu Tamura                                                                                                                                                     |
| 759 |    766.296988 |    195.072284 | Scott Hartman                                                                                                                                                   |
| 760 |    646.777464 |    329.529828 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 761 |    290.177442 |     90.069802 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 762 |    303.172158 |    387.564779 | Gareth Monger                                                                                                                                                   |
| 763 |    969.554117 |    283.346379 | Markus A. Grohme                                                                                                                                                |
| 764 |    867.613417 |    767.824464 | Steven Traver                                                                                                                                                   |
| 765 |    555.372636 |    697.497715 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                     |
| 766 |    383.353310 |      9.017897 | Birgit Lang                                                                                                                                                     |
| 767 |    135.582949 |    308.914488 | Andy Wilson                                                                                                                                                     |
| 768 |    867.695595 |    636.933911 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                        |
| 769 |    202.571460 |     42.579639 | Chuanixn Yu                                                                                                                                                     |
| 770 |    419.159893 |    466.822326 | Kamil S. Jaron                                                                                                                                                  |
| 771 |     33.100508 |    148.721485 | NA                                                                                                                                                              |
| 772 |    317.110929 |    150.597429 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                 |
| 773 |    773.116279 |    345.847102 | Erika Schumacher                                                                                                                                                |
| 774 |    556.127158 |    224.917152 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                         |
| 775 |    968.822960 |    457.499141 | NA                                                                                                                                                              |
| 776 |    974.508147 |    762.412766 | Matt Crook                                                                                                                                                      |
| 777 |      9.789259 |    212.489353 | Zimices                                                                                                                                                         |
| 778 |    432.629546 |    461.742264 | Andy Wilson                                                                                                                                                     |
| 779 |   1011.811962 |    429.837754 | Caleb M. Brown                                                                                                                                                  |
| 780 |     99.086611 |    477.452462 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                               |
| 781 |    840.899802 |    490.310654 | Tasman Dixon                                                                                                                                                    |
| 782 |    716.635912 |     92.132079 | Ferran Sayol                                                                                                                                                    |
| 783 |     14.782607 |    335.640690 | JCGiron                                                                                                                                                         |
| 784 |    812.645753 |    611.420454 | Gareth Monger                                                                                                                                                   |
| 785 |    992.146678 |    522.723813 | L. Shyamal                                                                                                                                                      |
| 786 |    348.936633 |     63.310274 | Matt Martyniuk                                                                                                                                                  |
| 787 |    713.429813 |     29.153832 | T. Michael Keesey                                                                                                                                               |
| 788 |    412.535929 |    353.333021 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                              |
| 789 |    796.253811 |     31.837753 | Gareth Monger                                                                                                                                                   |
| 790 |     84.817746 |     61.279473 | Matt Crook                                                                                                                                                      |
| 791 |    677.390678 |    231.149878 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                |
| 792 |    709.188547 |    167.885308 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 793 |    787.437872 |    344.406938 | Matt Crook                                                                                                                                                      |
| 794 |    306.858738 |    610.850512 | Andrew A. Farke                                                                                                                                                 |
| 795 |    726.519087 |    412.062226 | Sean McCann                                                                                                                                                     |
| 796 |    166.670746 |    450.475845 | Francesco “Architetto” Rollandin                                                                                                                                |
| 797 |    860.727150 |    312.009015 | Gareth Monger                                                                                                                                                   |
| 798 |    398.283921 |    790.729998 | Matt Crook                                                                                                                                                      |
| 799 |    262.192760 |    302.882744 | Zimices                                                                                                                                                         |
| 800 |    829.393948 |      8.219883 | Andy Wilson                                                                                                                                                     |
| 801 |     19.724713 |    601.024577 | C. Camilo Julián-Caballero                                                                                                                                      |
| 802 |    818.555813 |    556.678444 | Tasman Dixon                                                                                                                                                    |
| 803 |    747.740383 |    480.873845 | Pete Buchholz                                                                                                                                                   |
| 804 |    961.762083 |     18.070955 | Esme Ashe-Jepson                                                                                                                                                |
| 805 |    604.245767 |     54.923625 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 806 |    569.871385 |    780.670348 | Matt Crook                                                                                                                                                      |
| 807 |    665.174463 |    507.683581 | Jaime Headden                                                                                                                                                   |
| 808 |    642.104758 |    752.849364 | Margot Michaud                                                                                                                                                  |
| 809 |    816.180208 |    100.109324 | Matt Crook                                                                                                                                                      |
| 810 |    615.654880 |    677.767293 | Anthony Caravaggi                                                                                                                                               |
| 811 |    686.345639 |    726.342075 | RS                                                                                                                                                              |
| 812 |    350.751845 |      7.924755 | L. Shyamal                                                                                                                                                      |
| 813 |    467.752704 |    193.781888 | Zimices                                                                                                                                                         |
| 814 |    971.929272 |    781.864811 | Steven Coombs                                                                                                                                                   |
| 815 |    756.669708 |    686.026300 | Gareth Monger                                                                                                                                                   |
| 816 |    765.065830 |    545.735656 | Neil Kelley                                                                                                                                                     |
| 817 |    913.294534 |    353.088030 | Ingo Braasch                                                                                                                                                    |
| 818 |    618.778728 |    655.589732 | Pranav Iyer (grey ideas)                                                                                                                                        |
| 819 |    821.148767 |    261.537127 | Scott Hartman                                                                                                                                                   |
| 820 |    763.525683 |    353.114348 | Joanna Wolfe                                                                                                                                                    |
| 821 |    337.510320 |    255.872729 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 822 |   1005.686699 |    538.096232 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                           |
| 823 |    583.717042 |     69.690923 | Gareth Monger                                                                                                                                                   |
| 824 |    506.261911 |    622.088369 | Jagged Fang Designs                                                                                                                                             |
| 825 |    356.619767 |    774.417478 | Jonathan Wells                                                                                                                                                  |
| 826 |    948.353246 |    147.132098 | Jagged Fang Designs                                                                                                                                             |
| 827 |    460.528502 |    697.735737 | Mykle Hoban                                                                                                                                                     |
| 828 |    481.118906 |    360.631647 | Zimices                                                                                                                                                         |
| 829 |    520.098278 |    397.976970 | Chris A. Hamilton                                                                                                                                               |
| 830 |    220.243310 |    576.437234 | Margot Michaud                                                                                                                                                  |
| 831 |    940.598652 |    579.159903 | Smokeybjb (modified by Mike Keesey)                                                                                                                             |
| 832 |    896.039952 |    466.821625 | Chris huh                                                                                                                                                       |
| 833 |    695.301176 |    630.024277 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                    |
| 834 |    247.703729 |    188.517191 | Birgit Lang                                                                                                                                                     |
| 835 |    352.733741 |     26.793896 | Gabriela Palomo-Munoz                                                                                                                                           |
| 836 |    417.507508 |     75.154679 | Jagged Fang Designs                                                                                                                                             |
| 837 |    950.005637 |    668.032167 | Matt Crook                                                                                                                                                      |
| 838 |    557.621314 |    412.296288 | Steven Traver                                                                                                                                                   |
| 839 |    514.285257 |    125.813214 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 840 |    666.972534 |    581.181723 | Chase Brownstein                                                                                                                                                |
| 841 |      8.833016 |     82.715289 | Cesar Julian                                                                                                                                                    |
| 842 |     16.246873 |    429.585338 | Scott Hartman                                                                                                                                                   |
| 843 |    867.927762 |    149.559661 | L. Shyamal                                                                                                                                                      |
| 844 |    140.857258 |    707.670893 | Notafly (vectorized by T. Michael Keesey)                                                                                                                       |
| 845 |    982.433032 |    673.503240 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                       |
| 846 |    534.960813 |    794.047437 | Zimices                                                                                                                                                         |
| 847 |    348.987433 |    388.486590 | Michelle Site                                                                                                                                                   |
| 848 |    715.623455 |    110.641494 | Zimices                                                                                                                                                         |
| 849 |    320.288712 |    750.690221 | David Liao                                                                                                                                                      |
| 850 |    577.698411 |    384.409161 | Gareth Monger                                                                                                                                                   |
| 851 |    365.633405 |    493.526284 | Matt Dempsey                                                                                                                                                    |
| 852 |    375.809474 |    528.606938 | Gareth Monger                                                                                                                                                   |
| 853 |    140.846802 |     76.875052 | Markus A. Grohme                                                                                                                                                |
| 854 |    329.058088 |    170.263058 | Zimices                                                                                                                                                         |
| 855 |    195.965168 |    269.388589 | Luc Viatour (source photo) and Andreas Plank                                                                                                                    |
| 856 |    352.657384 |     89.480222 | Maxime Dahirel                                                                                                                                                  |
| 857 |    102.083842 |    449.906934 | Zimices                                                                                                                                                         |
| 858 |    385.913909 |    396.991636 | Chris huh                                                                                                                                                       |
| 859 |     42.119160 |     49.923394 | Steven Coombs                                                                                                                                                   |
| 860 |    183.963544 |    787.557373 | Zimices                                                                                                                                                         |
| 861 |    553.881420 |    688.079453 | Caleb M. Brown                                                                                                                                                  |
| 862 |    114.358454 |    243.195005 | T. Michael Keesey                                                                                                                                               |
| 863 |    832.591301 |    139.468923 | Zimices                                                                                                                                                         |
| 864 |    438.487502 |    217.235211 | Christine Axon                                                                                                                                                  |
| 865 |    407.779118 |    250.625507 | Kanako Bessho-Uehara                                                                                                                                            |
| 866 |    174.368775 |    312.406903 | Steven Traver                                                                                                                                                   |
| 867 |    944.087977 |    594.956827 | Maija Karala                                                                                                                                                    |
| 868 |    746.283971 |    367.118817 | Harold N Eyster                                                                                                                                                 |
| 869 |    414.511490 |    570.386938 | Markus A. Grohme                                                                                                                                                |
| 870 |      4.101882 |     55.826730 | Steven Traver                                                                                                                                                   |
| 871 |    661.365957 |    468.222116 | Gareth Monger                                                                                                                                                   |
| 872 |    490.953859 |    632.683481 | Scott Hartman                                                                                                                                                   |
| 873 |    536.359795 |    500.958494 | Terpsichores                                                                                                                                                    |
| 874 |    427.882440 |    141.643592 | NA                                                                                                                                                              |
| 875 |    237.054693 |    714.117954 | Matt Crook                                                                                                                                                      |
| 876 |    572.929939 |    608.968280 | Katie S. Collins                                                                                                                                                |
| 877 |    381.374920 |    594.980877 | T. Michael Keesey                                                                                                                                               |
| 878 |    472.072271 |     58.636345 | Margot Michaud                                                                                                                                                  |
| 879 |    161.385167 |      4.630463 | Scott Hartman                                                                                                                                                   |
| 880 |    554.303262 |    293.288914 | Matt Celeskey                                                                                                                                                   |
| 881 |    525.671813 |    564.746357 | Matt Crook                                                                                                                                                      |
| 882 |    592.640949 |    682.368959 | Nobu Tamura and T. Michael Keesey                                                                                                                               |
| 883 |    400.210469 |    148.485451 | Matt Crook                                                                                                                                                      |
| 884 |    238.934008 |    594.151405 | Chuanixn Yu                                                                                                                                                     |
| 885 |    541.966515 |    360.333898 | NA                                                                                                                                                              |
| 886 |    649.239448 |    791.982134 | Griensteidl and T. Michael Keesey                                                                                                                               |
| 887 |    572.846279 |    306.000289 | Gustav Mützel                                                                                                                                                   |
| 888 |    836.967193 |     99.214582 | Beth Reinke                                                                                                                                                     |
| 889 |    801.906308 |    791.231695 | Maija Karala                                                                                                                                                    |
| 890 |    134.803345 |    521.504577 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                      |
| 891 |    697.669932 |    422.803497 | Becky Barnes                                                                                                                                                    |
| 892 |    599.399060 |    341.790338 | Dean Schnabel                                                                                                                                                   |
| 893 |    469.950846 |     34.093590 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                 |
| 894 |    696.290683 |    107.990312 | Margot Michaud                                                                                                                                                  |
| 895 |    640.656424 |    218.660892 | Zimices                                                                                                                                                         |
| 896 |    827.557556 |    538.241512 | Pedro de Siracusa                                                                                                                                               |
| 897 |    280.283941 |    289.260597 | Christoph Schomburg                                                                                                                                             |
| 898 |    828.709709 |    651.231630 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                              |
| 899 |     71.086911 |    602.202778 | Gareth Monger                                                                                                                                                   |
| 900 |    735.294348 |     54.180360 | Erika Schumacher                                                                                                                                                |
| 901 |    329.617122 |    298.644700 | Zimices                                                                                                                                                         |
| 902 |    313.053000 |    583.463119 | Steven Traver                                                                                                                                                   |
| 903 |    291.367253 |     16.867613 | Zimices                                                                                                                                                         |
| 904 |    334.319843 |    176.546594 | NA                                                                                                                                                              |
| 905 |    452.430684 |    663.007055 | Zimices                                                                                                                                                         |

    #> Your tweet has been posted!
