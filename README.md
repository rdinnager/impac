
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

Alexander Schmidt-Lebuhn, Scott Reid, Steven Traver, Birgit Lang, Ernst
Haeckel (vectorized by T. Michael Keesey), Jagged Fang Designs, Michael
Scroggie, Yan Wong from drawing by T. F. Zimmermann, Cesar Julian,
Margot Michaud, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), Emil Schmidt (vectorized by Maxime
Dahirel), Nobu Tamura (vectorized by T. Michael Keesey), Andreas Trepte
(vectorized by T. Michael Keesey), Chris huh, xgirouxb, Young and Zhao
(1972:figure 4), modified by Michael P. Taylor, Mark Hannaford (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Sibi
(vectorized by T. Michael Keesey), FunkMonk, L. Shyamal, Maija Karala,
Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Robert Gay, Yan Wong from
illustration by Jules Richard (1907), Jerry Oldenettel (vectorized by T.
Michael Keesey), Rebecca Groom, Kailah Thorn & Ben King, Matt Crook,
Gareth Monger, Carlos Cano-Barbacil, Maxime Dahirel, Steven Haddock
• Jellywatch.org, DW Bapst, modified from Ishitani et al. 2016,
Christoph Schomburg, Jaime Headden, Tyler Greenfield, Kosta Mumcuoglu
(vectorized by T. Michael Keesey), Scott Hartman, Caleb Brown, Mali’o
Kodis, image from the “Proceedings of the Zoological Society of London”,
Michele Tobias, Dmitry Bogdanov (vectorized by T. Michael Keesey), M
Kolmann, James R. Spotila and Ray Chatterji, Lafage, Shyamal, Smokeybjb,
Zachary Quigley, Campbell Fleming, Félix Landry Yuan, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Nobu Tamura, vectorized by Zimices, Timothy Knepp of the U.S.
Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Julio Garza, H. Filhol (vectorized by T. Michael Keesey),
Daniel Jaron, Lily Hughes, Brad McFeeters (vectorized by T. Michael
Keesey), Zimices, based in Mauricio Antón skeletal, Anthony Caravaggi,
Philip Chalmers (vectorized by T. Michael Keesey), Dean Schnabel,
Smokeybjb, vectorized by Zimices, Sharon Wegner-Larsen, T. Michael
Keesey (vectorization) and Nadiatalent (photography), Ray Simpson
(vectorized by T. Michael Keesey), Ferran Sayol, T. Michael Keesey,
Andrew A. Farke, modified from original by H. Milne Edwards, Matt
Dempsey, Lukasiniho, Sarah Werning, Nobu Tamura, Kamil S. Jaron,
S.Martini, Jake Warner, Y. de Hoev. (vectorized by T. Michael Keesey),
Zimices, Eyal Bartov, Michelle Site, Falconaumanni and T. Michael
Keesey, Noah Schlottman, photo by Casey Dunn, Richard Ruggiero,
vectorized by Zimices, Maky (vectorization), Gabriella Skollar
(photography), Rebecca Lewis (editing), Darren Naish (vectorize by T.
Michael Keesey), Yan Wong, Jimmy Bernot, Melissa Broussard, Roberto Díaz
Sibaja, Beth Reinke, Kai R. Caspar, Robbie N. Cada (vectorized by T.
Michael Keesey), Tracy A. Heath, Nobu Tamura (modified by T. Michael
Keesey), Chris Hay, Gabriela Palomo-Munoz, Abraão Leite, Andrew A.
Farke, Mathew Stewart, \[unknown\], Maha Ghazal, Stanton F. Fink
(vectorized by T. Michael Keesey), Elizabeth Parker, Noah Schlottman,
photo from Casey Dunn, Francis de Laporte de Castelnau (vectorized by T.
Michael Keesey), Gregor Bucher, Max Farnworth, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Ingo Braasch, Matt Celeskey, Tauana J. Cunha, Manabu
Sakamoto, David Liao, Tasman Dixon, Alex Slavenko, Mark Miller, Pete
Buchholz, Renata F. Martins, Dori <dori@merr.info> (source photo) and
Nevit Dilmen, Patrick Strutzenberger, Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, , Paul Baker (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Julien
Louys, Aline M. Ghilardi, Rachel Shoop, C. Camilo Julián-Caballero,
Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Caleb M. Brown,
Francisco Manuel Blanco (vectorized by T. Michael Keesey), Felix Vaux,
JCGiron, Bennet McComish, photo by Avenue, Harold N Eyster, Marie
Russell, J Levin W (illustration) and T. Michael Keesey (vectorization),
Apokryltaros (vectorized by T. Michael Keesey), Ghedoghedo, vectorized
by Zimices, DW Bapst (modified from Bulman, 1970), Iain Reid, Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Mathieu Basille, Original scheme by ‘Haplochromis’,
vectorized by Roberto Díaz Sibaja, T. Michael Keesey (after MPF),
Pollyanna von Knorring and T. Michael Keesey, Collin Gross, Liftarn,
Ghedoghedo (vectorized by T. Michael Keesey), Frank Förster (based on a
picture by Jerry Kirkhart; modified by T. Michael Keesey), terngirl,
Haplochromis (vectorized by T. Michael Keesey), David Orr, Tyler
Greenfield and Dean Schnabel, Andreas Hejnol, Alexandre Vong, Renato
Santos, Terpsichores, T. Michael Keesey (after Mauricio Antón), Moussa
Direct Ltd. (photography) and T. Michael Keesey (vectorization), Mo
Hassan, H. F. O. March (vectorized by T. Michael Keesey), Milton Tan,
Dein Freund der Baum (vectorized by T. Michael Keesey), Dmitry Bogdanov,
Mercedes Yrayzoz (vectorized by T. Michael Keesey), Crystal Maier,
Griensteidl and T. Michael Keesey, Chris Jennings (vectorized by A.
Verrière), Steven Coombs, Mathew Wedel, Obsidian Soul (vectorized by T.
Michael Keesey), Noah Schlottman, Robbie Cada (vectorized by T. Michael
Keesey), Emily Willoughby, Lankester Edwin Ray (vectorized by T. Michael
Keesey), Mattia Menchetti, Jonathan Wells, Joanna Wolfe, FunkMonk
(Michael B.H.; vectorized by T. Michael Keesey), Matt Hayes, Original
drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja, Ville-Veikko
Sinkkonen, Audrey Ely, Sergio A. Muñoz-Gómez, Darren Naish (vectorized
by T. Michael Keesey), Frederick William Frohawk (vectorized by T.
Michael Keesey), nicubunu, Jaime A. Headden (vectorized by T. Michael
Keesey), T. Michael Keesey (from a photo by Maximilian Paradiz), Meyers
Konversations-Lexikon 1897 (vectorized: Yan Wong), Amanda Katzer, Karla
Martinez, Owen Jones, Julia B McHugh, Martien Brand (original photo),
Renato Santos (vector silhouette), T. Michael Keesey (after C. De
Muizon), Ewald Rübsamen, Armin Reindl, Henry Lydecker, Steve
Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael
Keesey (vectorization), Lindberg (vectorized by T. Michael Keesey),
Charles R. Knight (vectorized by T. Michael Keesey), Katie S. Collins,
Neil Kelley, Stuart Humphries, T. Michael Keesey (vectorization); Yves
Bousquet (photography), Steven Coombs (vectorized by T. Michael Keesey),
Stacy Spensley (Modified), Remes K, Ortega F, Fierro I, Joger U, Kosma
R, et al., Mario Quevedo, T. Tischler, Tony Ayling (vectorized by T.
Michael Keesey), Mali’o Kodis, photograph by Hans Hillewaert, Yan Wong
from photo by Denes Emoke, Unknown (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Kenneth Lacovara (vectorized by
T. Michael Keesey), Francisco Gascó (modified by Michael P. Taylor),
Mark Hofstetter (vectorized by T. Michael Keesey), Benjamint444,
Ghedoghedo, Ville Koistinen and T. Michael Keesey, Chloé Schmidt,
Verisimilus, Stemonitis (photography) and T. Michael Keesey
(vectorization), Rebecca Groom (Based on Photo by Andreas Trepte), Matt
Martyniuk (modified by T. Michael Keesey), Matt Martyniuk (modified by
Serenchia), Mali’o Kodis, photograph property of National Museums of
Northern Ireland, Darius Nau, Joris van der Ham (vectorized by T.
Michael Keesey), Caleb M. Gordon, Mariana Ruiz (vectorized by T. Michael
Keesey), André Karwath (vectorized by T. Michael Keesey), Hans
Hillewaert (vectorized by T. Michael Keesey), Jose Carlos Arenas-Monroy,
Estelle Bourdon, Nicholas J. Czaplewski, vectorized by Zimices, Javiera
Constanzo, Jakovche, Jim Bendon (photography) and T. Michael Keesey
(vectorization), Didier Descouens (vectorized by T. Michael Keesey),
Ryan Cupo, Mali’o Kodis, image by Rebecca Ritger, John Conway, Thibaut
Brunet, Matus Valach, Michael Day, Christine Axon, Original photo by
Andrew Murray, vectorized by Roberto Díaz Sibaja, Joedison Rocha,
Mathilde Cordellier, Matt Martyniuk (vectorized by T. Michael Keesey),
T. Michael Keesey (from a mount by Allis Markham), Lukas Panzarin, Louis
Ranjard, Dr. Thomas G. Barnes, USFWS, Plukenet, Qiang Ou, Aadx, CDC
(Alissa Eckert; Dan Higgins), Mali’o Kodis, photograph by Cordell
Expeditions at Cal Academy, Kent Elson Sorgon, Noah Schlottman, photo by
Carol Cummings, T. Michael Keesey (photo by J. M. Garg), Becky Barnes,
Mike Hanson, Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis
M. Chiappe, Robert Bruce Horsfall, vectorized by Zimices, Sarefo
(vectorized by T. Michael Keesey), Dmitry Bogdanov, vectorized by
Zimices, wsnaccad, DW Bapst (Modified from Bulman, 1964), Lip Kee Yap
(vectorized by T. Michael Keesey), Luc Viatour (source photo) and
Andreas Plank, Mali’o Kodis, photograph by John Slapcinsky, Tom Tarrant
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Vanessa Guerra, Xavier Giroux-Bougard

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    938.045340 |    264.137540 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|   2 |    527.863587 |    659.784344 | Scott Reid                                                                                                                                                            |
|   3 |    671.232826 |    723.058796 | Steven Traver                                                                                                                                                         |
|   4 |    152.123488 |    658.053336 | Birgit Lang                                                                                                                                                           |
|   5 |    641.951692 |    129.699515 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
|   6 |    122.115594 |    388.260027 | Jagged Fang Designs                                                                                                                                                   |
|   7 |    944.093563 |    672.147896 | Michael Scroggie                                                                                                                                                      |
|   8 |    741.736900 |    321.449082 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
|   9 |    530.964787 |    594.574469 | Cesar Julian                                                                                                                                                          |
|  10 |    255.545401 |     26.067348 | Margot Michaud                                                                                                                                                        |
|  11 |    118.038070 |    448.832575 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
|  12 |    808.407734 |    150.702194 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
|  13 |    453.532316 |    223.022160 | NA                                                                                                                                                                    |
|  14 |    462.183486 |    472.680526 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  15 |    273.359722 |    752.028248 | Jagged Fang Designs                                                                                                                                                   |
|  16 |     80.695367 |    227.270053 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
|  17 |    670.602143 |    772.689123 | NA                                                                                                                                                                    |
|  18 |    138.928086 |    565.416074 | Chris huh                                                                                                                                                             |
|  19 |    847.548256 |    507.192988 | Steven Traver                                                                                                                                                         |
|  20 |    420.363702 |    681.295925 | xgirouxb                                                                                                                                                              |
|  21 |    454.479087 |    112.709061 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
|  22 |    331.176312 |    483.364974 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
|  23 |    654.957332 |    668.174489 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
|  24 |    256.660038 |    645.282885 | FunkMonk                                                                                                                                                              |
|  25 |    408.439855 |    330.157816 | L. Shyamal                                                                                                                                                            |
|  26 |    687.233684 |    475.349396 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  27 |    610.779018 |    336.586918 | Maija Karala                                                                                                                                                          |
|  28 |    256.142235 |    108.802667 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  29 |    288.349871 |    389.657156 | Robert Gay                                                                                                                                                            |
|  30 |    842.722113 |    764.057918 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
|  31 |    241.437840 |    234.948606 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
|  32 |    488.817910 |    283.676402 | Margot Michaud                                                                                                                                                        |
|  33 |    114.809808 |    755.590996 | Rebecca Groom                                                                                                                                                         |
|  34 |    696.687043 |     98.368318 | Kailah Thorn & Ben King                                                                                                                                               |
|  35 |    519.478550 |     43.754897 | Margot Michaud                                                                                                                                                        |
|  36 |    272.738555 |    292.308501 | L. Shyamal                                                                                                                                                            |
|  37 |     92.315923 |    533.016144 | Matt Crook                                                                                                                                                            |
|  38 |    875.873215 |    383.459694 | Gareth Monger                                                                                                                                                         |
|  39 |     88.772752 |     91.896647 | Carlos Cano-Barbacil                                                                                                                                                  |
|  40 |    775.203892 |    676.562482 | Maxime Dahirel                                                                                                                                                        |
|  41 |    604.010595 |    249.283331 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|  42 |    247.072408 |    543.450141 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
|  43 |    912.251152 |     94.649907 | Christoph Schomburg                                                                                                                                                   |
|  44 |    463.674426 |    438.171292 | Jaime Headden                                                                                                                                                         |
|  45 |    385.725906 |    566.384335 | Tyler Greenfield                                                                                                                                                      |
|  46 |    572.524573 |    465.281367 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
|  47 |    718.110042 |    190.936737 | Scott Hartman                                                                                                                                                         |
|  48 |    453.900037 |    403.643046 | Caleb Brown                                                                                                                                                           |
|  49 |    824.366827 |    672.864493 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
|  50 |    327.146600 |    155.124201 | Michele Tobias                                                                                                                                                        |
|  51 |    720.040937 |    633.762899 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  52 |    447.401177 |    767.573758 | FunkMonk                                                                                                                                                              |
|  53 |    777.528074 |    357.070908 | M Kolmann                                                                                                                                                             |
|  54 |    160.285961 |     40.129079 | Birgit Lang                                                                                                                                                           |
|  55 |    541.763397 |    182.203408 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  56 |    944.842570 |    167.654723 | NA                                                                                                                                                                    |
|  57 |    617.899649 |    547.774235 | Lafage                                                                                                                                                                |
|  58 |     64.898638 |    599.225779 | Margot Michaud                                                                                                                                                        |
|  59 |    350.324562 |     49.532626 | Matt Crook                                                                                                                                                            |
|  60 |    508.684962 |    720.647701 | Maija Karala                                                                                                                                                          |
|  61 |    304.740370 |    714.308701 | Shyamal                                                                                                                                                               |
|  62 |    796.281475 |     40.211982 | Jaime Headden                                                                                                                                                         |
|  63 |    482.046353 |    526.029838 | Margot Michaud                                                                                                                                                        |
|  64 |    374.776666 |    420.941404 | Smokeybjb                                                                                                                                                             |
|  65 |    886.854336 |    312.421275 | FunkMonk                                                                                                                                                              |
|  66 |     79.699736 |    357.151666 | Chris huh                                                                                                                                                             |
|  67 |    420.608990 |    136.813230 | Zachary Quigley                                                                                                                                                       |
|  68 |    857.375155 |    155.735516 | Campbell Fleming                                                                                                                                                      |
|  69 |    180.784268 |    597.630194 | Scott Hartman                                                                                                                                                         |
|  70 |    687.200953 |    577.330350 | xgirouxb                                                                                                                                                              |
|  71 |    516.853641 |    315.093990 | Scott Hartman                                                                                                                                                         |
|  72 |    100.912696 |    666.443450 | Jagged Fang Designs                                                                                                                                                   |
|  73 |    369.817167 |    654.723239 | Félix Landry Yuan                                                                                                                                                     |
|  74 |    146.891812 |    213.445655 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  75 |    255.273164 |    788.547442 | Scott Hartman                                                                                                                                                         |
|  76 |    634.626166 |    619.981166 | Chris huh                                                                                                                                                             |
|  77 |    946.941450 |    734.678766 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  78 |    190.379216 |    345.783681 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
|  79 |    331.754187 |    251.648347 | Julio Garza                                                                                                                                                           |
|  80 |    836.983567 |     22.732906 | Gareth Monger                                                                                                                                                         |
|  81 |    145.609313 |    130.118934 | FunkMonk                                                                                                                                                              |
|  82 |    506.780669 |    358.814484 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                           |
|  83 |    334.165905 |    341.643605 | Daniel Jaron                                                                                                                                                          |
|  84 |    361.312500 |    362.429806 | Lily Hughes                                                                                                                                                           |
|  85 |    143.175282 |    759.407797 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  86 |     31.275407 |     17.560955 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
|  87 |    629.747971 |    100.497465 | Michael Scroggie                                                                                                                                                      |
|  88 |   1013.255025 |    504.748908 | Gareth Monger                                                                                                                                                         |
|  89 |    214.939671 |    151.909001 | Anthony Caravaggi                                                                                                                                                     |
|  90 |    127.039027 |    334.773158 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
|  91 |    159.783387 |    625.370599 | Dean Schnabel                                                                                                                                                         |
|  92 |    977.389550 |     32.902341 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
|  93 |    556.359857 |    628.848964 | Steven Traver                                                                                                                                                         |
|  94 |     39.158606 |    506.435075 | Matt Crook                                                                                                                                                            |
|  95 |    757.572643 |    139.151520 | Sharon Wegner-Larsen                                                                                                                                                  |
|  96 |    979.405645 |    569.680577 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
|  97 |    338.423781 |    657.600078 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
|  98 |    664.517828 |    246.946312 | Margot Michaud                                                                                                                                                        |
|  99 |    157.051506 |     90.415700 | Ferran Sayol                                                                                                                                                          |
| 100 |    469.038649 |    734.925321 | Jagged Fang Designs                                                                                                                                                   |
| 101 |    688.818318 |     16.170197 | T. Michael Keesey                                                                                                                                                     |
| 102 |    374.327289 |    385.560531 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 103 |    984.659487 |    119.618320 | Matt Dempsey                                                                                                                                                          |
| 104 |    855.690283 |    720.242204 | Lukasiniho                                                                                                                                                            |
| 105 |    465.759035 |    578.418975 | Sarah Werning                                                                                                                                                         |
| 106 |    578.016023 |    763.139631 | Margot Michaud                                                                                                                                                        |
| 107 |    802.771134 |    789.549096 | Nobu Tamura                                                                                                                                                           |
| 108 |    184.718435 |    768.174507 | Kamil S. Jaron                                                                                                                                                        |
| 109 |    871.696754 |    664.119849 | Scott Reid                                                                                                                                                            |
| 110 |    355.690348 |    266.042609 | S.Martini                                                                                                                                                             |
| 111 |    161.724226 |     21.692911 | Dean Schnabel                                                                                                                                                         |
| 112 |    426.388741 |    181.867830 | Jake Warner                                                                                                                                                           |
| 113 |    674.704945 |     11.042476 | Birgit Lang                                                                                                                                                           |
| 114 |     12.009244 |    501.926155 | Jagged Fang Designs                                                                                                                                                   |
| 115 |     40.249447 |    714.211663 | Matt Crook                                                                                                                                                            |
| 116 |     14.298190 |     32.339947 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                         |
| 117 |    364.687546 |     91.716148 | Jaime Headden                                                                                                                                                         |
| 118 |    974.870379 |      9.895124 | Jagged Fang Designs                                                                                                                                                   |
| 119 |    642.341653 |    495.937132 | Zimices                                                                                                                                                               |
| 120 |    394.249247 |    639.014708 | Eyal Bartov                                                                                                                                                           |
| 121 |     48.263177 |    791.210824 | Anthony Caravaggi                                                                                                                                                     |
| 122 |    976.567099 |    759.850460 | xgirouxb                                                                                                                                                              |
| 123 |    595.780974 |     52.790474 | M Kolmann                                                                                                                                                             |
| 124 |    661.400783 |    416.299714 | Chris huh                                                                                                                                                             |
| 125 |    126.469965 |    307.817499 | T. Michael Keesey                                                                                                                                                     |
| 126 |    284.386745 |    227.582259 | Jagged Fang Designs                                                                                                                                                   |
| 127 |     30.714228 |    285.229397 | Michelle Site                                                                                                                                                         |
| 128 |    159.135019 |     31.058554 | Jagged Fang Designs                                                                                                                                                   |
| 129 |    842.340136 |     55.153025 | Ferran Sayol                                                                                                                                                          |
| 130 |    949.813035 |    455.316940 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 131 |    986.423487 |    233.707747 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 132 |    945.004120 |    396.081490 | Matt Crook                                                                                                                                                            |
| 133 |    433.458464 |    459.302848 | Jagged Fang Designs                                                                                                                                                   |
| 134 |    341.710587 |    779.831277 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 135 |    503.777822 |    634.279611 | NA                                                                                                                                                                    |
| 136 |    456.723085 |    261.753221 | Campbell Fleming                                                                                                                                                      |
| 137 |    574.146099 |    565.820104 | Gareth Monger                                                                                                                                                         |
| 138 |    595.224126 |    118.400240 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                        |
| 139 |    578.857167 |    688.418456 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 140 |    722.208392 |    645.170941 | Lafage                                                                                                                                                                |
| 141 |    264.012555 |    240.040490 | T. Michael Keesey                                                                                                                                                     |
| 142 |     54.862545 |    770.464178 | NA                                                                                                                                                                    |
| 143 |    879.691598 |    725.056337 | Ferran Sayol                                                                                                                                                          |
| 144 |    771.709499 |    782.362915 | Ferran Sayol                                                                                                                                                          |
| 145 |    414.275558 |    105.982589 | Yan Wong                                                                                                                                                              |
| 146 |    328.839650 |    301.462555 | Jimmy Bernot                                                                                                                                                          |
| 147 |     40.849059 |    651.945067 | Melissa Broussard                                                                                                                                                     |
| 148 |    541.855501 |    317.790189 | Smokeybjb                                                                                                                                                             |
| 149 |    998.762761 |    136.598648 | Maija Karala                                                                                                                                                          |
| 150 |     18.845843 |    666.990799 | Roberto Díaz Sibaja                                                                                                                                                   |
| 151 |     11.958398 |    427.708545 | Steven Traver                                                                                                                                                         |
| 152 |    518.096964 |    773.593340 | Matt Crook                                                                                                                                                            |
| 153 |    436.731814 |    552.921146 | Zimices                                                                                                                                                               |
| 154 |    174.399476 |    416.874616 | NA                                                                                                                                                                    |
| 155 |    779.321528 |    406.454993 | Scott Hartman                                                                                                                                                         |
| 156 |     23.676467 |    109.609856 | NA                                                                                                                                                                    |
| 157 |    470.684241 |    339.425401 | Beth Reinke                                                                                                                                                           |
| 158 |   1016.879809 |     19.108198 | Kai R. Caspar                                                                                                                                                         |
| 159 |   1003.345129 |    407.040283 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 160 |    531.668462 |     22.055489 | Ferran Sayol                                                                                                                                                          |
| 161 |    612.695080 |    100.994618 | T. Michael Keesey                                                                                                                                                     |
| 162 |    430.487608 |     21.295913 | Tracy A. Heath                                                                                                                                                        |
| 163 |    994.225392 |     55.960554 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 164 |    269.323179 |    203.042298 | Chris Hay                                                                                                                                                             |
| 165 |    863.699820 |    191.959930 | NA                                                                                                                                                                    |
| 166 |      3.845842 |    710.707440 | Margot Michaud                                                                                                                                                        |
| 167 |    135.138949 |    298.429684 | Scott Hartman                                                                                                                                                         |
| 168 |    500.729309 |     20.905210 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 169 |    753.961269 |    220.908931 | Ferran Sayol                                                                                                                                                          |
| 170 |    715.507931 |    215.088760 | Matt Crook                                                                                                                                                            |
| 171 |    728.673579 |    386.954905 | Abraão Leite                                                                                                                                                          |
| 172 |    410.358194 |     54.178902 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 173 |    215.332604 |    604.517715 | Andrew A. Farke                                                                                                                                                       |
| 174 |    341.539105 |    294.764246 | T. Michael Keesey                                                                                                                                                     |
| 175 |    770.795449 |      8.113909 | Mathew Stewart                                                                                                                                                        |
| 176 |    748.397462 |    720.596482 | Yan Wong                                                                                                                                                              |
| 177 |    592.592422 |    143.525302 | Margot Michaud                                                                                                                                                        |
| 178 |     10.826136 |     94.785968 | \[unknown\]                                                                                                                                                           |
| 179 |    853.060734 |    786.622918 | Maha Ghazal                                                                                                                                                           |
| 180 |     15.412468 |    437.275514 | Scott Hartman                                                                                                                                                         |
| 181 |     62.661550 |    680.246151 | Ferran Sayol                                                                                                                                                          |
| 182 |    177.512366 |    129.096761 | Dean Schnabel                                                                                                                                                         |
| 183 |    365.465975 |    762.857512 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 184 |    583.135424 |    126.881536 | M Kolmann                                                                                                                                                             |
| 185 |    122.839136 |      2.686306 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 186 |     56.383737 |    396.181947 | Zimices                                                                                                                                                               |
| 187 |     36.431627 |    477.967475 | Ferran Sayol                                                                                                                                                          |
| 188 |    979.760211 |    453.750465 | NA                                                                                                                                                                    |
| 189 |    840.956727 |    154.255495 | Elizabeth Parker                                                                                                                                                      |
| 190 |    189.877208 |    148.611601 | NA                                                                                                                                                                    |
| 191 |     63.154156 |     66.226160 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 192 |    996.688569 |    301.276502 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 193 |    449.259641 |    615.725151 | Christoph Schomburg                                                                                                                                                   |
| 194 |    963.933751 |    358.253097 | Ferran Sayol                                                                                                                                                          |
| 195 |    567.074360 |    119.254347 | Julio Garza                                                                                                                                                           |
| 196 |    863.213479 |     52.840696 | Matt Crook                                                                                                                                                            |
| 197 |      4.566593 |    276.740556 | NA                                                                                                                                                                    |
| 198 |    509.178368 |    553.966647 | Steven Traver                                                                                                                                                         |
| 199 |     82.390287 |    772.666583 | Gregor Bucher, Max Farnworth                                                                                                                                          |
| 200 |    286.955060 |    196.124087 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 201 |    982.332265 |    211.081289 | Ingo Braasch                                                                                                                                                          |
| 202 |    723.909874 |    605.913777 | NA                                                                                                                                                                    |
| 203 |    117.800219 |     51.759177 | Matt Celeskey                                                                                                                                                         |
| 204 |     44.106379 |     45.811014 | Tauana J. Cunha                                                                                                                                                       |
| 205 |    281.735732 |    345.958480 | Melissa Broussard                                                                                                                                                     |
| 206 |    784.090231 |     17.183218 | Kamil S. Jaron                                                                                                                                                        |
| 207 |     25.741869 |    332.567948 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 208 |    471.929043 |    780.919481 | Maija Karala                                                                                                                                                          |
| 209 |    874.622499 |    125.035399 | Manabu Sakamoto                                                                                                                                                       |
| 210 |     38.856021 |    246.035147 | Zimices                                                                                                                                                               |
| 211 |    917.139585 |    375.079122 | Tauana J. Cunha                                                                                                                                                       |
| 212 |    458.391913 |     88.819031 | David Liao                                                                                                                                                            |
| 213 |    475.161730 |    644.836477 | Margot Michaud                                                                                                                                                        |
| 214 |    620.327344 |    490.625279 | Michele Tobias                                                                                                                                                        |
| 215 |    797.882604 |     78.442466 | Jagged Fang Designs                                                                                                                                                   |
| 216 |    214.334433 |    379.597138 | Michael Scroggie                                                                                                                                                      |
| 217 |    133.174815 |    320.991483 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 218 |    597.053675 |    654.066340 | Matt Crook                                                                                                                                                            |
| 219 |    405.375826 |    796.383500 | Tasman Dixon                                                                                                                                                          |
| 220 |    558.131568 |    570.364157 | Andrew A. Farke                                                                                                                                                       |
| 221 |    210.061821 |    286.449491 | FunkMonk                                                                                                                                                              |
| 222 |    601.118422 |    516.305650 | Zimices                                                                                                                                                               |
| 223 |    154.323919 |    693.040438 | Alex Slavenko                                                                                                                                                         |
| 224 |    706.759398 |    565.144810 | Zimices                                                                                                                                                               |
| 225 |    552.035270 |    385.502353 | Mark Miller                                                                                                                                                           |
| 226 |      4.741950 |    222.175258 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 227 |    921.226185 |    359.394558 | Margot Michaud                                                                                                                                                        |
| 228 |     33.813997 |    315.521286 | Matt Crook                                                                                                                                                            |
| 229 |     16.664464 |    419.000202 | NA                                                                                                                                                                    |
| 230 |    433.240910 |    374.056867 | Alex Slavenko                                                                                                                                                         |
| 231 |    429.833717 |    602.859270 | Chris huh                                                                                                                                                             |
| 232 |    899.095620 |    755.460192 | Pete Buchholz                                                                                                                                                         |
| 233 |     24.209032 |    590.249443 | Kai R. Caspar                                                                                                                                                         |
| 234 |    292.616908 |    738.088071 | Margot Michaud                                                                                                                                                        |
| 235 |   1011.781044 |    169.589712 | Zimices                                                                                                                                                               |
| 236 |    582.004197 |     15.225083 | Margot Michaud                                                                                                                                                        |
| 237 |    585.243219 |     56.673069 | NA                                                                                                                                                                    |
| 238 |    371.185967 |    788.787932 | Renata F. Martins                                                                                                                                                     |
| 239 |    855.179822 |    683.621662 | Steven Traver                                                                                                                                                         |
| 240 |    748.764479 |    338.778592 | Pete Buchholz                                                                                                                                                         |
| 241 |    216.476728 |    489.161272 | Tasman Dixon                                                                                                                                                          |
| 242 |    589.074053 |    235.294292 | Sarah Werning                                                                                                                                                         |
| 243 |    981.525015 |    527.354051 | Chris huh                                                                                                                                                             |
| 244 |    901.365623 |    628.021298 | Tasman Dixon                                                                                                                                                          |
| 245 |    748.643964 |     96.866117 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 246 |    351.544714 |    545.460048 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 247 |     60.961212 |    251.066743 | Margot Michaud                                                                                                                                                        |
| 248 |    825.657679 |    373.830164 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 249 |    177.917666 |    216.195006 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 250 |    981.476092 |    376.288345 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 251 |    735.504255 |    552.232683 | NA                                                                                                                                                                    |
| 252 |    404.975004 |      5.594783 | Patrick Strutzenberger                                                                                                                                                |
| 253 |    868.217232 |    782.496696 | NA                                                                                                                                                                    |
| 254 |    770.684481 |    127.912169 | Beth Reinke                                                                                                                                                           |
| 255 |    155.440060 |    505.969021 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 256 |    322.864608 |    435.020561 |                                                                                                                                                                       |
| 257 |    366.177442 |    205.275749 | Zimices                                                                                                                                                               |
| 258 |    724.361806 |    230.833606 | Christoph Schomburg                                                                                                                                                   |
| 259 |    743.129268 |    598.610868 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 260 |    144.741533 |    776.931419 | Julien Louys                                                                                                                                                          |
| 261 |    643.270230 |     81.109646 | Tasman Dixon                                                                                                                                                          |
| 262 |    931.042435 |    791.830093 | Roberto Díaz Sibaja                                                                                                                                                   |
| 263 |    998.618932 |    275.639438 | NA                                                                                                                                                                    |
| 264 |   1010.281067 |    362.669652 | Zimices                                                                                                                                                               |
| 265 |    806.094564 |    631.726294 | Aline M. Ghilardi                                                                                                                                                     |
| 266 |    211.667978 |    598.944577 | Rachel Shoop                                                                                                                                                          |
| 267 |    565.440622 |    780.762392 | Tyler Greenfield                                                                                                                                                      |
| 268 |     13.707305 |    404.852258 | C. Camilo Julián-Caballero                                                                                                                                            |
| 269 |   1004.900154 |    743.297427 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 270 |    643.171422 |      3.515107 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 271 |    989.812202 |    384.884313 | T. Michael Keesey                                                                                                                                                     |
| 272 |    311.591305 |    212.290704 | Scott Hartman                                                                                                                                                         |
| 273 |     49.202316 |     60.510901 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                 |
| 274 |     85.386834 |    317.834107 | Caleb M. Brown                                                                                                                                                        |
| 275 |    513.099255 |     62.910515 | Scott Hartman                                                                                                                                                         |
| 276 |    217.922017 |    263.924495 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                             |
| 277 |    717.562883 |    162.820515 | Felix Vaux                                                                                                                                                            |
| 278 |    781.438685 |    144.828270 | JCGiron                                                                                                                                                               |
| 279 |    384.476103 |     84.892285 | Jagged Fang Designs                                                                                                                                                   |
| 280 |    991.874258 |    581.248906 | Bennet McComish, photo by Avenue                                                                                                                                      |
| 281 |    501.889639 |    250.222847 | Harold N Eyster                                                                                                                                                       |
| 282 |    171.529576 |    712.240441 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 283 |    746.098850 |    771.383678 | T. Michael Keesey                                                                                                                                                     |
| 284 |    792.303288 |    631.700663 | T. Michael Keesey                                                                                                                                                     |
| 285 |    648.646785 |    589.832355 | Caleb M. Brown                                                                                                                                                        |
| 286 |    126.401885 |    278.038456 | Jaime Headden                                                                                                                                                         |
| 287 |      5.234860 |    283.456449 | Scott Hartman                                                                                                                                                         |
| 288 |    780.709439 |    113.752157 | NA                                                                                                                                                                    |
| 289 |    308.305359 |    583.042659 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
| 290 |     25.233258 |    396.926274 | Zimices                                                                                                                                                               |
| 291 |    166.751735 |    517.317952 | Gareth Monger                                                                                                                                                         |
| 292 |    810.203628 |    642.885620 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 293 |   1011.819340 |     69.058105 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 294 |     46.942562 |     27.522024 | NA                                                                                                                                                                    |
| 295 |    938.638663 |     24.138181 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 296 |    829.483663 |    332.403506 | Birgit Lang                                                                                                                                                           |
| 297 |    176.074019 |    509.891130 | Jagged Fang Designs                                                                                                                                                   |
| 298 |    534.469012 |    338.224324 | Zimices                                                                                                                                                               |
| 299 |    782.409206 |    348.122123 | Tasman Dixon                                                                                                                                                          |
| 300 |    696.645051 |    439.163612 | T. Michael Keesey                                                                                                                                                     |
| 301 |      5.074522 |    117.372476 | Yan Wong                                                                                                                                                              |
| 302 |    415.680562 |    156.635853 | Steven Traver                                                                                                                                                         |
| 303 |    605.557806 |    737.005833 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 304 |    204.829455 |    626.705786 | NA                                                                                                                                                                    |
| 305 |    224.976142 |    691.128539 | Gareth Monger                                                                                                                                                         |
| 306 |    724.207862 |    522.239091 | Beth Reinke                                                                                                                                                           |
| 307 |    549.237984 |    762.871486 | Chris huh                                                                                                                                                             |
| 308 |     78.734111 |    412.395548 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 309 |     39.421232 |    647.383112 | Matt Crook                                                                                                                                                            |
| 310 |    949.560706 |    363.413327 | Dean Schnabel                                                                                                                                                         |
| 311 |    140.250316 |    401.513510 | Lukasiniho                                                                                                                                                            |
| 312 |    702.561264 |    218.013020 | NA                                                                                                                                                                    |
| 313 |    776.290236 |     97.884850 | Tasman Dixon                                                                                                                                                          |
| 314 |    758.464167 |    162.562278 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 315 |    979.469149 |    427.997024 | Steven Traver                                                                                                                                                         |
| 316 |    255.516077 |    625.096750 | Marie Russell                                                                                                                                                         |
| 317 |    369.971318 |     80.024233 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 318 |    587.232462 |    273.849622 | NA                                                                                                                                                                    |
| 319 |    184.753253 |    631.151309 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 320 |    546.223284 |    360.673455 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 321 |    771.289980 |    351.987453 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 322 |    241.180679 |    326.981049 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 323 |    649.577456 |    187.644876 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 324 |    602.886651 |     43.749167 | Jagged Fang Designs                                                                                                                                                   |
| 325 |    258.090083 |    689.878662 | Iain Reid                                                                                                                                                             |
| 326 |    708.992884 |    211.425546 | Matt Crook                                                                                                                                                            |
| 327 |    811.737646 |    379.535559 | Scott Hartman                                                                                                                                                         |
| 328 |    425.169188 |    644.931154 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 329 |    979.534327 |    403.439335 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 330 |    234.729206 |    689.821182 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 331 |    729.621556 |    592.162583 | Matt Crook                                                                                                                                                            |
| 332 |    659.404219 |    279.098382 | Sarah Werning                                                                                                                                                         |
| 333 |     12.687811 |    137.160666 | Mathieu Basille                                                                                                                                                       |
| 334 |    500.893278 |    443.583394 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 335 |    687.890370 |    171.638866 | Yan Wong                                                                                                                                                              |
| 336 |    193.451235 |    634.086197 | Ferran Sayol                                                                                                                                                          |
| 337 |     21.927136 |    742.795218 | FunkMonk                                                                                                                                                              |
| 338 |    275.465003 |    609.513398 | T. Michael Keesey                                                                                                                                                     |
| 339 |    116.889759 |    309.778820 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 340 |     23.667081 |    614.751480 | Zimices                                                                                                                                                               |
| 341 |    651.690511 |    345.745212 | Zimices                                                                                                                                                               |
| 342 |    117.797552 |    244.820382 | Zimices                                                                                                                                                               |
| 343 |    759.972915 |    752.657367 | Margot Michaud                                                                                                                                                        |
| 344 |    556.906204 |    107.584005 | Gareth Monger                                                                                                                                                         |
| 345 |     12.463309 |    239.377922 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 346 |     48.713776 |    526.860031 | Christoph Schomburg                                                                                                                                                   |
| 347 |     51.621558 |    682.157941 | T. Michael Keesey                                                                                                                                                     |
| 348 |    838.190991 |    775.346612 | Gareth Monger                                                                                                                                                         |
| 349 |    365.881048 |    630.190005 | NA                                                                                                                                                                    |
| 350 |    803.224915 |    613.263531 | Collin Gross                                                                                                                                                          |
| 351 |   1017.447681 |    478.550315 | Liftarn                                                                                                                                                               |
| 352 |    625.310750 |    444.051408 | Gareth Monger                                                                                                                                                         |
| 353 |    564.091341 |    561.480523 | Zimices                                                                                                                                                               |
| 354 |    498.696418 |     79.868389 | Matt Celeskey                                                                                                                                                         |
| 355 |    298.494806 |    593.001919 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 356 |    260.603674 |    330.256315 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                   |
| 357 |    396.244208 |    484.604283 | Jagged Fang Designs                                                                                                                                                   |
| 358 |   1012.321282 |      6.302633 | terngirl                                                                                                                                                              |
| 359 |    490.068664 |    209.402184 | Margot Michaud                                                                                                                                                        |
| 360 |    295.848012 |     15.777648 | Matt Crook                                                                                                                                                            |
| 361 |     57.173992 |    271.226336 | Gareth Monger                                                                                                                                                         |
| 362 |    646.656487 |    405.908677 | Steven Traver                                                                                                                                                         |
| 363 |    675.786513 |    230.682902 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 364 |    879.480262 |    239.964883 | Steven Traver                                                                                                                                                         |
| 365 |    833.397047 |    394.599317 | Lukasiniho                                                                                                                                                            |
| 366 |    198.136958 |    165.609147 | Shyamal                                                                                                                                                               |
| 367 |    535.627971 |    760.073462 | David Orr                                                                                                                                                             |
| 368 |    436.183861 |    620.833172 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 369 |    290.149084 |    569.079530 | Kamil S. Jaron                                                                                                                                                        |
| 370 |    240.551874 |    453.150320 | Sarah Werning                                                                                                                                                         |
| 371 |    945.140770 |    127.694545 | Tauana J. Cunha                                                                                                                                                       |
| 372 |    197.057619 |    406.101022 | Margot Michaud                                                                                                                                                        |
| 373 |    491.377635 |    194.768848 | Ferran Sayol                                                                                                                                                          |
| 374 |    325.543646 |    425.780903 | Andreas Hejnol                                                                                                                                                        |
| 375 |    977.148742 |    787.761139 | Michelle Site                                                                                                                                                         |
| 376 |    759.342306 |    117.869386 | Alexandre Vong                                                                                                                                                        |
| 377 |     25.335467 |    549.020611 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 378 |    152.671101 |    546.184830 | Manabu Sakamoto                                                                                                                                                       |
| 379 |    407.613870 |    263.162981 | Renato Santos                                                                                                                                                         |
| 380 |     17.164886 |    394.272038 | Matt Crook                                                                                                                                                            |
| 381 |    537.859814 |    110.669351 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 382 |    189.855784 |    761.003139 | Terpsichores                                                                                                                                                          |
| 383 |    275.371325 |     24.837444 | Steven Traver                                                                                                                                                         |
| 384 |    689.417404 |    601.144193 | Gareth Monger                                                                                                                                                         |
| 385 |    628.518584 |    515.578713 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 386 |    718.776890 |    172.722237 | NA                                                                                                                                                                    |
| 387 |    409.450584 |     28.999876 | T. Michael Keesey                                                                                                                                                     |
| 388 |    267.535904 |    447.885460 | Sarah Werning                                                                                                                                                         |
| 389 |    770.830307 |    724.063074 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                   |
| 390 |    796.640392 |    394.709943 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 391 |    270.762836 |    197.037193 | Zimices                                                                                                                                                               |
| 392 |    654.483171 |    284.455844 | Tasman Dixon                                                                                                                                                          |
| 393 |    768.063050 |    112.753421 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
| 394 |    521.010179 |    353.165675 | T. Michael Keesey                                                                                                                                                     |
| 395 |    974.073958 |     66.331250 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 396 |    781.818655 |    709.186302 | Mo Hassan                                                                                                                                                             |
| 397 |    160.983282 |    768.631049 | Cesar Julian                                                                                                                                                          |
| 398 |     29.727232 |     54.336213 | NA                                                                                                                                                                    |
| 399 |    427.436539 |    592.905882 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 400 |    702.541629 |    707.529760 | Dean Schnabel                                                                                                                                                         |
| 401 |     77.692614 |    622.281911 | Tauana J. Cunha                                                                                                                                                       |
| 402 |    105.605664 |    684.639953 | Milton Tan                                                                                                                                                            |
| 403 |    441.396206 |     49.018836 | Gareth Monger                                                                                                                                                         |
| 404 |    958.461820 |     10.239201 | Christoph Schomburg                                                                                                                                                   |
| 405 |    405.322056 |    347.273983 | Sarah Werning                                                                                                                                                         |
| 406 |    314.772122 |     26.299119 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 407 |     98.078804 |    674.316871 | Carlos Cano-Barbacil                                                                                                                                                  |
| 408 |    117.226990 |    366.351283 | Scott Hartman                                                                                                                                                         |
| 409 |    736.132078 |    205.412342 | Dmitry Bogdanov                                                                                                                                                       |
| 410 |    969.655996 |    416.367675 | Scott Hartman                                                                                                                                                         |
| 411 |    509.293449 |      5.161764 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 412 |    125.972444 |    226.352698 | Crystal Maier                                                                                                                                                         |
| 413 |     16.983386 |    779.963265 | Margot Michaud                                                                                                                                                        |
| 414 |      6.630055 |     81.363716 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 415 |    562.861374 |    796.094957 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 416 |    531.354570 |    491.082235 | Scott Hartman                                                                                                                                                         |
| 417 |    210.410728 |    396.096389 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 418 |    470.419032 |    375.244905 | Chris huh                                                                                                                                                             |
| 419 |    182.963622 |    128.747005 | Matt Crook                                                                                                                                                            |
| 420 |    999.362303 |     95.966962 | Steven Traver                                                                                                                                                         |
| 421 |    378.721318 |    677.802936 | Steven Coombs                                                                                                                                                         |
| 422 |     57.778396 |     35.974653 | Kai R. Caspar                                                                                                                                                         |
| 423 |    935.280880 |    365.132332 | Chris huh                                                                                                                                                             |
| 424 |    413.764137 |    451.054470 | Mathew Wedel                                                                                                                                                          |
| 425 |    471.689545 |    679.314074 | T. Michael Keesey                                                                                                                                                     |
| 426 |    129.401198 |    723.078072 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 427 |   1018.059844 |    778.552978 | T. Michael Keesey                                                                                                                                                     |
| 428 |    308.923969 |     70.864534 | FunkMonk                                                                                                                                                              |
| 429 |    531.332259 |      5.855400 | Noah Schlottman                                                                                                                                                       |
| 430 |     70.514496 |      4.836019 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                         |
| 431 |     18.567876 |    677.816729 | NA                                                                                                                                                                    |
| 432 |    992.809829 |    622.179692 | Emily Willoughby                                                                                                                                                      |
| 433 |    297.757913 |     82.399090 | Matt Crook                                                                                                                                                            |
| 434 |    948.039971 |    352.734128 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 435 |     87.691147 |    322.041840 | FunkMonk                                                                                                                                                              |
| 436 |    957.560606 |     71.696852 | Mattia Menchetti                                                                                                                                                      |
| 437 |    658.781814 |    189.358335 | xgirouxb                                                                                                                                                              |
| 438 |    716.899899 |     12.259116 | Steven Traver                                                                                                                                                         |
| 439 |    342.409441 |    224.990960 | terngirl                                                                                                                                                              |
| 440 |    328.908988 |    118.126860 | Dean Schnabel                                                                                                                                                         |
| 441 |     32.525684 |    179.483020 | NA                                                                                                                                                                    |
| 442 |    282.345074 |    576.789458 | David Orr                                                                                                                                                             |
| 443 |    462.324624 |     53.945308 | Maija Karala                                                                                                                                                          |
| 444 |    889.154304 |    113.981840 | Jonathan Wells                                                                                                                                                        |
| 445 |   1015.833576 |    606.073557 | Joanna Wolfe                                                                                                                                                          |
| 446 |    930.067362 |    112.150682 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 447 |     82.804552 |    421.870113 | Birgit Lang                                                                                                                                                           |
| 448 |    408.344903 |    656.990772 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 449 |    563.991394 |    787.536852 | Felix Vaux                                                                                                                                                            |
| 450 |    662.018185 |    786.147283 | NA                                                                                                                                                                    |
| 451 |    440.205480 |    581.863145 | L. Shyamal                                                                                                                                                            |
| 452 |    243.477373 |    466.541939 | Jagged Fang Designs                                                                                                                                                   |
| 453 |    645.862699 |    435.120301 | L. Shyamal                                                                                                                                                            |
| 454 |    876.116122 |    403.727227 | Matt Hayes                                                                                                                                                            |
| 455 |    450.804179 |    359.691826 | Matt Crook                                                                                                                                                            |
| 456 |    829.623595 |    403.293647 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 457 |    476.275236 |    247.327612 | Maxime Dahirel                                                                                                                                                        |
| 458 |    439.303656 |    362.638939 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 459 |    492.254565 |    673.410918 | Carlos Cano-Barbacil                                                                                                                                                  |
| 460 |    528.899894 |    684.147620 | Steven Coombs                                                                                                                                                         |
| 461 |    693.351572 |    752.560275 | Matt Crook                                                                                                                                                            |
| 462 |    134.843799 |    512.915517 | Ferran Sayol                                                                                                                                                          |
| 463 |    930.720490 |    404.501529 | Carlos Cano-Barbacil                                                                                                                                                  |
| 464 |    771.886871 |    207.823920 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 465 |    335.423411 |    546.729262 | Christoph Schomburg                                                                                                                                                   |
| 466 |    950.176277 |    517.122815 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 467 |    100.266322 |    322.995879 | Audrey Ely                                                                                                                                                            |
| 468 |    695.180002 |     81.595572 | Scott Hartman                                                                                                                                                         |
| 469 |    703.088605 |    354.692680 | Matt Crook                                                                                                                                                            |
| 470 |    984.649610 |    744.324643 | Matt Crook                                                                                                                                                            |
| 471 |   1004.633779 |    321.489612 | Tasman Dixon                                                                                                                                                          |
| 472 |    185.399458 |    541.035249 | T. Michael Keesey                                                                                                                                                     |
| 473 |     52.255685 |    338.167435 | Scott Hartman                                                                                                                                                         |
| 474 |    182.042389 |    470.918581 | Zimices                                                                                                                                                               |
| 475 |    131.732365 |     56.050232 | Renato Santos                                                                                                                                                         |
| 476 |    525.487297 |    737.831128 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 477 |    929.919226 |    349.523425 | Margot Michaud                                                                                                                                                        |
| 478 |     40.975433 |    690.834120 | Margot Michaud                                                                                                                                                        |
| 479 |    260.449547 |    222.132987 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 480 |    407.066077 |    198.930814 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 481 |     15.844161 |    365.639374 | Margot Michaud                                                                                                                                                        |
| 482 |    401.249868 |     99.696151 | nicubunu                                                                                                                                                              |
| 483 |    810.412726 |    318.750095 | Ferran Sayol                                                                                                                                                          |
| 484 |    821.196886 |     84.231514 | FunkMonk                                                                                                                                                              |
| 485 |    353.001836 |    529.847370 | Jagged Fang Designs                                                                                                                                                   |
| 486 |    879.860477 |    621.811410 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 487 |    948.545143 |    541.785100 | NA                                                                                                                                                                    |
| 488 |    100.977016 |    286.229263 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 489 |    494.015870 |    418.292309 | Ferran Sayol                                                                                                                                                          |
| 490 |    716.114088 |    118.734391 | Beth Reinke                                                                                                                                                           |
| 491 |     10.427540 |    454.471614 | Christoph Schomburg                                                                                                                                                   |
| 492 |    541.933907 |     20.118336 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 493 |     19.334626 |    788.592028 | Jagged Fang Designs                                                                                                                                                   |
| 494 |     39.253687 |    144.086226 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 495 |    669.127895 |     31.992009 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 496 |    767.589850 |    633.279576 | Tasman Dixon                                                                                                                                                          |
| 497 |    968.883348 |    371.099818 | Gareth Monger                                                                                                                                                         |
| 498 |    639.756653 |    504.983421 | Margot Michaud                                                                                                                                                        |
| 499 |     12.014698 |    739.060522 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 500 |    977.836712 |    549.339998 | Amanda Katzer                                                                                                                                                         |
| 501 |    626.413846 |    282.947401 | Zimices                                                                                                                                                               |
| 502 |    492.788617 |    237.130216 | Christoph Schomburg                                                                                                                                                   |
| 503 |    229.090260 |    447.808954 | Zimices                                                                                                                                                               |
| 504 |    349.353037 |    730.383282 | Zimices                                                                                                                                                               |
| 505 |    767.898485 |     68.151586 | Matt Crook                                                                                                                                                            |
| 506 |    702.141299 |    613.420823 | Jagged Fang Designs                                                                                                                                                   |
| 507 |    395.936165 |    172.487326 | Nobu Tamura                                                                                                                                                           |
| 508 |    949.707002 |     33.217199 | Gareth Monger                                                                                                                                                         |
| 509 |    798.911572 |    639.362993 | Karla Martinez                                                                                                                                                        |
| 510 |    667.563498 |    320.817596 | Daniel Jaron                                                                                                                                                          |
| 511 |    194.681348 |     36.480182 | Owen Jones                                                                                                                                                            |
| 512 |    831.732014 |    146.777611 | Gareth Monger                                                                                                                                                         |
| 513 |    816.079347 |    246.851560 | Maija Karala                                                                                                                                                          |
| 514 |    868.828110 |    736.414403 | Julia B McHugh                                                                                                                                                        |
| 515 |    609.040270 |    606.196403 | Kai R. Caspar                                                                                                                                                         |
| 516 |     32.509375 |    120.032149 | Kamil S. Jaron                                                                                                                                                        |
| 517 |    319.151028 |    285.288419 | Chris huh                                                                                                                                                             |
| 518 |    702.267047 |    668.666175 | NA                                                                                                                                                                    |
| 519 |    315.561758 |    525.269363 | Matt Crook                                                                                                                                                            |
| 520 |    772.058178 |    766.732801 | T. Michael Keesey                                                                                                                                                     |
| 521 |    121.792937 |    171.802722 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 522 |    111.751632 |    192.392701 | Zimices                                                                                                                                                               |
| 523 |     32.292290 |    746.572218 | Andrew A. Farke                                                                                                                                                       |
| 524 |    669.699125 |     22.219675 | Christoph Schomburg                                                                                                                                                   |
| 525 |    725.169109 |    219.779347 | Rebecca Groom                                                                                                                                                         |
| 526 |     68.095102 |    779.155348 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 527 |    779.336115 |    363.173872 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 528 |    226.800237 |    602.505549 | Zimices                                                                                                                                                               |
| 529 |    385.912208 |    369.409759 | Andrew A. Farke                                                                                                                                                       |
| 530 |    749.230895 |     74.958388 | Lukasiniho                                                                                                                                                            |
| 531 |    325.791726 |    189.139166 | Chris huh                                                                                                                                                             |
| 532 |      7.342482 |    364.222467 | Zimices                                                                                                                                                               |
| 533 |    354.102162 |    517.863711 | Rebecca Groom                                                                                                                                                         |
| 534 |    308.592899 |    124.703469 | Ewald Rübsamen                                                                                                                                                        |
| 535 |    263.813579 |    684.974508 | NA                                                                                                                                                                    |
| 536 |    429.325590 |    652.474374 | Sarah Werning                                                                                                                                                         |
| 537 |    189.538401 |    621.047717 | Zimices                                                                                                                                                               |
| 538 |    250.094468 |    668.790503 | T. Michael Keesey                                                                                                                                                     |
| 539 |    730.064870 |    563.132481 | Nobu Tamura                                                                                                                                                           |
| 540 |    909.222272 |    756.385568 | Shyamal                                                                                                                                                               |
| 541 |    593.584744 |    756.379457 | FunkMonk                                                                                                                                                              |
| 542 |   1003.887039 |     31.239991 | Sharon Wegner-Larsen                                                                                                                                                  |
| 543 |    740.538646 |    486.624705 | Jagged Fang Designs                                                                                                                                                   |
| 544 |    887.714063 |    358.691404 | Michael Scroggie                                                                                                                                                      |
| 545 |    605.319191 |     76.111514 | Steven Traver                                                                                                                                                         |
| 546 |    149.136579 |    187.762906 | Matt Crook                                                                                                                                                            |
| 547 |    341.104771 |    206.424273 | T. Michael Keesey                                                                                                                                                     |
| 548 |    156.777386 |    394.174569 | Carlos Cano-Barbacil                                                                                                                                                  |
| 549 |    191.162894 |    730.098567 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 550 |    960.685216 |    325.805400 | Armin Reindl                                                                                                                                                          |
| 551 |    335.125406 |    285.498773 | Henry Lydecker                                                                                                                                                        |
| 552 |    217.821271 |    777.634115 | FunkMonk                                                                                                                                                              |
| 553 |    678.312564 |    246.912339 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 554 |    752.539468 |     89.479351 | Tracy A. Heath                                                                                                                                                        |
| 555 |    654.650530 |    103.865622 | T. Michael Keesey                                                                                                                                                     |
| 556 |    308.549866 |    609.669758 | T. Michael Keesey                                                                                                                                                     |
| 557 |    819.980476 |    745.695319 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 558 |    949.313388 |    379.055233 | Steven Traver                                                                                                                                                         |
| 559 |    543.091426 |    795.570915 | NA                                                                                                                                                                    |
| 560 |    264.629631 |    135.627306 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 561 |    218.881935 |    723.142928 | David Orr                                                                                                                                                             |
| 562 |    727.082325 |    544.607185 | Steven Traver                                                                                                                                                         |
| 563 |    636.652082 |    358.751525 | Matt Crook                                                                                                                                                            |
| 564 |    878.013540 |    144.113628 | Scott Hartman                                                                                                                                                         |
| 565 |    620.297033 |    569.523604 | Katie S. Collins                                                                                                                                                      |
| 566 |    133.873821 |    711.558278 | Scott Hartman                                                                                                                                                         |
| 567 |    905.137230 |    207.717828 | Jimmy Bernot                                                                                                                                                          |
| 568 |    379.741543 |    454.847983 | Neil Kelley                                                                                                                                                           |
| 569 |    777.670185 |    160.028602 | Stuart Humphries                                                                                                                                                      |
| 570 |    576.708083 |    380.573415 | Scott Hartman                                                                                                                                                         |
| 571 |    956.437685 |    554.188655 | Matt Crook                                                                                                                                                            |
| 572 |     69.217916 |     53.053901 | Steven Traver                                                                                                                                                         |
| 573 |    361.476033 |    100.536546 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 574 |    169.164236 |    226.259735 | Michael Scroggie                                                                                                                                                      |
| 575 |    157.384273 |    785.487317 | NA                                                                                                                                                                    |
| 576 |    627.921484 |    726.689133 | NA                                                                                                                                                                    |
| 577 |    473.914024 |    380.981591 | NA                                                                                                                                                                    |
| 578 |    550.896469 |    743.338518 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 579 |     22.750210 |    645.050734 | NA                                                                                                                                                                    |
| 580 |    691.543320 |    743.978467 | Joanna Wolfe                                                                                                                                                          |
| 581 |    665.876762 |    760.608679 | Scott Hartman                                                                                                                                                         |
| 582 |    808.676536 |    367.788505 | Stacy Spensley (Modified)                                                                                                                                             |
| 583 |    626.853900 |    758.463043 | T. Michael Keesey                                                                                                                                                     |
| 584 |     31.369568 |    166.747917 | Andrew A. Farke                                                                                                                                                       |
| 585 |     55.591668 |    480.429123 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 586 |    154.350393 |    427.544751 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 587 |    534.093490 |    501.965358 | Collin Gross                                                                                                                                                          |
| 588 |    916.425480 |    344.563891 | NA                                                                                                                                                                    |
| 589 |    202.673058 |    122.065576 | Zimices                                                                                                                                                               |
| 590 |    960.549948 |     89.766681 | Mario Quevedo                                                                                                                                                         |
| 591 |    700.734765 |    258.888737 | Tasman Dixon                                                                                                                                                          |
| 592 |    147.455484 |    496.214885 | Chris huh                                                                                                                                                             |
| 593 |    514.672320 |    761.107825 | Matt Crook                                                                                                                                                            |
| 594 |     26.754598 |    200.607505 | Margot Michaud                                                                                                                                                        |
| 595 |    966.337120 |     42.770589 | Chris huh                                                                                                                                                             |
| 596 |    294.610663 |    511.963696 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 597 |    124.340047 |    300.826102 | Rebecca Groom                                                                                                                                                         |
| 598 |    672.961173 |    209.151634 | Maija Karala                                                                                                                                                          |
| 599 |    819.600335 |     52.517072 | Scott Hartman                                                                                                                                                         |
| 600 |    943.839245 |    375.981845 | T. Tischler                                                                                                                                                           |
| 601 |    757.569300 |    793.058656 | Zimices                                                                                                                                                               |
| 602 |    424.711967 |    531.505017 | Steven Traver                                                                                                                                                         |
| 603 |    527.278259 |    404.407705 | Margot Michaud                                                                                                                                                        |
| 604 |    987.206944 |    606.346377 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 605 |    423.333266 |    797.564000 | Michelle Site                                                                                                                                                         |
| 606 |    678.711531 |    300.185195 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 607 |    414.077114 |     48.021659 | Zimices                                                                                                                                                               |
| 608 |    475.647779 |    486.794406 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 609 |    394.894738 |    405.720266 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 610 |     45.016168 |    730.904380 | Maija Karala                                                                                                                                                          |
| 611 |    705.603253 |    154.917976 | Zimices                                                                                                                                                               |
| 612 |    214.309276 |    751.177980 | Sarah Werning                                                                                                                                                         |
| 613 |    578.219407 |    392.975420 | T. Michael Keesey                                                                                                                                                     |
| 614 |    479.291913 |    697.097038 | Chris huh                                                                                                                                                             |
| 615 |    519.046836 |     14.324380 | Manabu Sakamoto                                                                                                                                                       |
| 616 |   1011.356638 |     81.883423 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 617 |     16.932236 |    539.501350 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 618 |    688.967539 |     85.927786 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 619 |    767.449224 |      2.098126 | Margot Michaud                                                                                                                                                        |
| 620 |    997.101753 |    758.617624 | Birgit Lang                                                                                                                                                           |
| 621 |    822.673458 |    399.508871 | Matt Crook                                                                                                                                                            |
| 622 |    995.150693 |    291.734509 | Ingo Braasch                                                                                                                                                          |
| 623 |    437.641652 |     94.331040 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 624 |    629.566889 |    747.499114 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
| 625 |    734.856774 |    388.328360 | NA                                                                                                                                                                    |
| 626 |    437.340166 |    344.635919 | Christoph Schomburg                                                                                                                                                   |
| 627 |    775.208823 |    741.476237 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 628 |    244.895195 |    310.368930 | Matt Crook                                                                                                                                                            |
| 629 |    852.870682 |    151.232566 | NA                                                                                                                                                                    |
| 630 |    361.004653 |    283.940887 | Matt Crook                                                                                                                                                            |
| 631 |    359.582060 |    597.723711 | Katie S. Collins                                                                                                                                                      |
| 632 |   1005.155077 |    596.099189 | T. Michael Keesey                                                                                                                                                     |
| 633 |    111.438975 |    671.759356 | Benjamint444                                                                                                                                                          |
| 634 |    426.448662 |    255.113627 | Lukasiniho                                                                                                                                                            |
| 635 |    278.473941 |     74.848820 | Gareth Monger                                                                                                                                                         |
| 636 |    535.703955 |    441.161598 | Ghedoghedo                                                                                                                                                            |
| 637 |    354.683120 |    396.549233 | Michelle Site                                                                                                                                                         |
| 638 |    320.773648 |    700.632929 | Tracy A. Heath                                                                                                                                                        |
| 639 |    420.619450 |    605.685392 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 640 |    553.964411 |    139.235663 | Iain Reid                                                                                                                                                             |
| 641 |    836.450424 |     76.560084 | Jagged Fang Designs                                                                                                                                                   |
| 642 |    247.927637 |    323.965387 | NA                                                                                                                                                                    |
| 643 |     83.822300 |    790.670144 | Chloé Schmidt                                                                                                                                                         |
| 644 |    380.256551 |    642.693740 | Scott Hartman                                                                                                                                                         |
| 645 |   1015.832465 |    104.031527 | Zimices                                                                                                                                                               |
| 646 |    157.708571 |    618.108642 | Verisimilus                                                                                                                                                           |
| 647 |     25.897479 |    262.949205 | Zimices                                                                                                                                                               |
| 648 |     43.768523 |    341.118618 | Gareth Monger                                                                                                                                                         |
| 649 |    329.419597 |    266.680456 | Gareth Monger                                                                                                                                                         |
| 650 |    508.358356 |    475.436721 | Melissa Broussard                                                                                                                                                     |
| 651 |   1014.723706 |    542.831288 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 652 |    853.734995 |     78.189868 | Sharon Wegner-Larsen                                                                                                                                                  |
| 653 |     96.795490 |    584.003454 | Ferran Sayol                                                                                                                                                          |
| 654 |    675.246332 |    275.295670 | Maija Karala                                                                                                                                                          |
| 655 |    752.568590 |    379.790481 | Margot Michaud                                                                                                                                                        |
| 656 |    307.056743 |     83.739875 | Scott Reid                                                                                                                                                            |
| 657 |    304.016015 |    587.081841 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 658 |     20.515346 |     60.374617 | Nobu Tamura                                                                                                                                                           |
| 659 |    972.054042 |    323.745244 | Melissa Broussard                                                                                                                                                     |
| 660 |    431.356655 |    627.100091 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 661 |    413.499563 |    584.672866 | NA                                                                                                                                                                    |
| 662 |    137.737563 |    288.439116 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
| 663 |    806.199575 |     43.554140 | Matt Crook                                                                                                                                                            |
| 664 |    472.223487 |     87.062733 | Gareth Monger                                                                                                                                                         |
| 665 |    302.702173 |    506.017998 | Gareth Monger                                                                                                                                                         |
| 666 |     75.635208 |    499.999269 | Ferran Sayol                                                                                                                                                          |
| 667 |    596.866450 |     47.843865 | Julio Garza                                                                                                                                                           |
| 668 |     45.579618 |    257.159036 | Sharon Wegner-Larsen                                                                                                                                                  |
| 669 |    567.277277 |    246.742620 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 670 |    665.323631 |    650.925187 | Zimices                                                                                                                                                               |
| 671 |    488.078470 |    361.068188 | Noah Schlottman                                                                                                                                                       |
| 672 |    839.066607 |    239.555872 | Alexandre Vong                                                                                                                                                        |
| 673 |    566.595213 |    619.749796 | Birgit Lang                                                                                                                                                           |
| 674 |     10.325906 |    494.347042 | Zimices                                                                                                                                                               |
| 675 |    995.534820 |    328.643850 | Darius Nau                                                                                                                                                            |
| 676 |    189.694599 |    364.066814 | Steven Traver                                                                                                                                                         |
| 677 |    334.921417 |    556.657939 | Scott Reid                                                                                                                                                            |
| 678 |   1014.099723 |    662.155545 | Alex Slavenko                                                                                                                                                         |
| 679 |    962.737384 |    349.916133 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 680 |    995.564181 |    343.918945 | Steven Traver                                                                                                                                                         |
| 681 |    784.902859 |    640.274345 | Katie S. Collins                                                                                                                                                      |
| 682 |    770.479001 |    125.181403 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 683 |    591.141903 |    395.361538 | Gareth Monger                                                                                                                                                         |
| 684 |     20.269530 |     70.996091 | Margot Michaud                                                                                                                                                        |
| 685 |    698.069292 |    228.398118 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 686 |    492.360110 |    659.294459 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 687 |     50.005267 |    473.828409 | Matt Crook                                                                                                                                                            |
| 688 |    425.822867 |    262.581407 | Melissa Broussard                                                                                                                                                     |
| 689 |    398.886655 |    257.989062 | NA                                                                                                                                                                    |
| 690 |   1001.590050 |    245.247222 | Gareth Monger                                                                                                                                                         |
| 691 |    522.109035 |    546.820030 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 692 |    147.835132 |    154.417054 | Caleb M. Gordon                                                                                                                                                       |
| 693 |    357.877240 |    776.362731 | Maija Karala                                                                                                                                                          |
| 694 |    352.637544 |    587.978123 | Zimices                                                                                                                                                               |
| 695 |    921.266761 |    136.410803 | NA                                                                                                                                                                    |
| 696 |    606.605035 |    441.372902 | Zimices                                                                                                                                                               |
| 697 |    377.719326 |     90.069431 | Zimices                                                                                                                                                               |
| 698 |    902.610367 |    613.560148 | Margot Michaud                                                                                                                                                        |
| 699 |    340.164244 |    681.588717 | Ferran Sayol                                                                                                                                                          |
| 700 |     20.162214 |    320.345836 | Julio Garza                                                                                                                                                           |
| 701 |    168.351022 |    237.154824 | Chris huh                                                                                                                                                             |
| 702 |    890.146148 |    273.449857 | Melissa Broussard                                                                                                                                                     |
| 703 |    829.073683 |    304.167102 | Tasman Dixon                                                                                                                                                          |
| 704 |    794.807473 |    775.030112 | T. Michael Keesey                                                                                                                                                     |
| 705 |   1005.996568 |    417.343259 | T. Michael Keesey                                                                                                                                                     |
| 706 |    706.213497 |    547.603094 | Steven Traver                                                                                                                                                         |
| 707 |    600.142942 |    129.033890 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 708 |    445.234685 |    569.101917 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 709 |    145.506664 |    616.239260 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                       |
| 710 |    169.637094 |    171.770166 | T. Michael Keesey                                                                                                                                                     |
| 711 |    358.117910 |    487.648239 | Mathew Wedel                                                                                                                                                          |
| 712 |    618.111866 |    399.756274 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 713 |    720.377188 |    769.942983 | NA                                                                                                                                                                    |
| 714 |    853.479534 |    346.388688 | Zimices                                                                                                                                                               |
| 715 |    123.651954 |    683.208725 | L. Shyamal                                                                                                                                                            |
| 716 |    962.339462 |    753.280286 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 717 |    876.981973 |    711.272849 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 718 |    779.865992 |    197.538450 | Zimices                                                                                                                                                               |
| 719 |    693.065063 |    692.578953 | Yan Wong                                                                                                                                                              |
| 720 |    857.881977 |    728.347327 | NA                                                                                                                                                                    |
| 721 |    395.248738 |     19.619433 | Estelle Bourdon                                                                                                                                                       |
| 722 |    173.270179 |    388.644267 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 723 |    825.179605 |     69.028693 | Javiera Constanzo                                                                                                                                                     |
| 724 |    292.803369 |    207.931638 | Jakovche                                                                                                                                                              |
| 725 |   1011.388168 |    682.118064 | Crystal Maier                                                                                                                                                         |
| 726 |    350.606122 |     31.679400 | Zimices                                                                                                                                                               |
| 727 |     50.166255 |    118.119679 | NA                                                                                                                                                                    |
| 728 |    611.884153 |    752.103249 | Gareth Monger                                                                                                                                                         |
| 729 |    346.004041 |    609.441498 | NA                                                                                                                                                                    |
| 730 |    971.127877 |    424.751917 | T. Michael Keesey                                                                                                                                                     |
| 731 |    403.314166 |    494.540722 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 732 |    847.229269 |    174.986951 | Roberto Díaz Sibaja                                                                                                                                                   |
| 733 |    622.622261 |     37.735695 | Jake Warner                                                                                                                                                           |
| 734 |    944.778521 |    777.066859 | Matt Crook                                                                                                                                                            |
| 735 |    743.330463 |    121.494256 | Joanna Wolfe                                                                                                                                                          |
| 736 |    524.104141 |    397.435934 | Ferran Sayol                                                                                                                                                          |
| 737 |    109.483207 |    606.420679 | NA                                                                                                                                                                    |
| 738 |    498.502991 |    492.815463 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 739 |    580.051716 |    733.595071 | Scott Reid                                                                                                                                                            |
| 740 |    153.844281 |      3.601555 | NA                                                                                                                                                                    |
| 741 |    950.907767 |    115.239768 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 742 |    457.998673 |     68.442335 | Kai R. Caspar                                                                                                                                                         |
| 743 |    295.015614 |    469.049669 | Ryan Cupo                                                                                                                                                             |
| 744 |    569.715634 |    135.176463 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 745 |    741.708978 |    641.262845 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 746 |    915.049650 |    626.469996 | NA                                                                                                                                                                    |
| 747 |    829.292726 |    649.892591 | NA                                                                                                                                                                    |
| 748 |    471.197412 |    616.899559 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 749 |     61.211630 |    260.520352 | Zimices                                                                                                                                                               |
| 750 |    451.666053 |    344.527096 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 751 |    570.460914 |    403.528896 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 752 |    982.939652 |    255.457165 | John Conway                                                                                                                                                           |
| 753 |    478.131165 |    196.859225 | Dean Schnabel                                                                                                                                                         |
| 754 |    380.734221 |    106.355148 | Zimices                                                                                                                                                               |
| 755 |    662.871391 |    256.179039 | Matt Crook                                                                                                                                                            |
| 756 |    113.632385 |     56.606701 | Carlos Cano-Barbacil                                                                                                                                                  |
| 757 |    143.024417 |    715.786124 | Matt Crook                                                                                                                                                            |
| 758 |    357.831791 |    325.796817 | NA                                                                                                                                                                    |
| 759 |    753.321752 |    111.728970 | NA                                                                                                                                                                    |
| 760 |    986.154511 |     20.274230 | Matt Crook                                                                                                                                                            |
| 761 |    826.757225 |    785.746187 | Katie S. Collins                                                                                                                                                      |
| 762 |    358.936497 |    253.166374 | NA                                                                                                                                                                    |
| 763 |    991.845562 |    129.134344 | Thibaut Brunet                                                                                                                                                        |
| 764 |    839.646531 |    196.019218 | Gareth Monger                                                                                                                                                         |
| 765 |    441.720588 |    185.479101 | Matus Valach                                                                                                                                                          |
| 766 |     57.070934 |     30.271495 | Eyal Bartov                                                                                                                                                           |
| 767 |    533.074866 |    769.173281 | Michael Day                                                                                                                                                           |
| 768 |    514.775763 |    230.307109 | Gareth Monger                                                                                                                                                         |
| 769 |     92.258672 |    649.732998 | Tasman Dixon                                                                                                                                                          |
| 770 |    278.480377 |      6.849090 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 771 |    212.059203 |    656.834245 | Christine Axon                                                                                                                                                        |
| 772 |   1007.064769 |    764.750962 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 773 |    571.429033 |    728.953673 | Joedison Rocha                                                                                                                                                        |
| 774 |    411.676572 |    550.909758 | Mathilde Cordellier                                                                                                                                                   |
| 775 |    141.488241 |    543.680270 | Gareth Monger                                                                                                                                                         |
| 776 |    364.837040 |    548.884925 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 777 |    376.723191 |    216.525457 | Steven Traver                                                                                                                                                         |
| 778 |    927.713683 |    391.164770 | Julia B McHugh                                                                                                                                                        |
| 779 |    192.165553 |    482.594085 | Iain Reid                                                                                                                                                             |
| 780 |    361.485676 |    195.018330 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 781 |   1000.601660 |    520.660971 | Lukas Panzarin                                                                                                                                                        |
| 782 |    373.940034 |    663.690105 | Louis Ranjard                                                                                                                                                         |
| 783 |   1010.050274 |    221.134431 | Tracy A. Heath                                                                                                                                                        |
| 784 |    949.076064 |    330.527443 | Tasman Dixon                                                                                                                                                          |
| 785 |    527.207122 |    222.394815 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 786 |    880.374985 |    106.025301 | Ferran Sayol                                                                                                                                                          |
| 787 |    731.872808 |    353.426308 | Zimices                                                                                                                                                               |
| 788 |    514.950825 |    499.433479 | Plukenet                                                                                                                                                              |
| 789 |    375.236086 |    343.886064 | NA                                                                                                                                                                    |
| 790 |    591.529119 |    271.901703 | Qiang Ou                                                                                                                                                              |
| 791 |    879.370641 |     39.275654 | Matt Crook                                                                                                                                                            |
| 792 |    464.372499 |    351.889291 | Jagged Fang Designs                                                                                                                                                   |
| 793 |    351.111751 |    671.626080 | Matt Crook                                                                                                                                                            |
| 794 |    192.950137 |    751.474909 | Gareth Monger                                                                                                                                                         |
| 795 |    917.694556 |    785.896764 | Aadx                                                                                                                                                                  |
| 796 |    351.502606 |    535.140336 | Scott Hartman                                                                                                                                                         |
| 797 |    678.292753 |    104.254449 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 798 |    542.966779 |    568.431269 | CDC (Alissa Eckert; Dan Higgins)                                                                                                                                      |
| 799 |    576.621774 |     91.103630 | Maxime Dahirel                                                                                                                                                        |
| 800 |    976.620573 |    514.570407 | Yan Wong                                                                                                                                                              |
| 801 |    667.234447 |    122.190555 | Zimices                                                                                                                                                               |
| 802 |    367.186530 |    507.051388 | Tasman Dixon                                                                                                                                                          |
| 803 |    455.325288 |    590.401982 | nicubunu                                                                                                                                                              |
| 804 |    355.956161 |    195.231456 | Matt Crook                                                                                                                                                            |
| 805 |    798.742073 |    741.290341 | Birgit Lang                                                                                                                                                           |
| 806 |    379.456393 |    154.452870 | Tasman Dixon                                                                                                                                                          |
| 807 |     27.996216 |    430.895904 | Matt Crook                                                                                                                                                            |
| 808 |    277.001113 |    211.402237 | Matt Crook                                                                                                                                                            |
| 809 |    204.242219 |    511.883570 | Zimices                                                                                                                                                               |
| 810 |    411.542391 |    557.068643 | Zimices                                                                                                                                                               |
| 811 |    553.927509 |    549.137689 | Margot Michaud                                                                                                                                                        |
| 812 |    562.585274 |    382.441673 | Margot Michaud                                                                                                                                                        |
| 813 |    388.041736 |    184.226375 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 814 |    411.161512 |     77.430415 | Kent Elson Sorgon                                                                                                                                                     |
| 815 |     43.565573 |    468.217627 | Beth Reinke                                                                                                                                                           |
| 816 |     27.142433 |    544.737126 | Gareth Monger                                                                                                                                                         |
| 817 |    237.402990 |     65.060653 | Katie S. Collins                                                                                                                                                      |
| 818 |    683.094768 |    540.560619 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 819 |     16.922573 |    174.465632 | Chris huh                                                                                                                                                             |
| 820 |    241.517205 |    695.908869 | Zimices                                                                                                                                                               |
| 821 |    914.707790 |    773.922516 | Birgit Lang                                                                                                                                                           |
| 822 |    873.342880 |     68.013048 | Zimices                                                                                                                                                               |
| 823 |    724.081665 |    719.996661 | Collin Gross                                                                                                                                                          |
| 824 |    442.457501 |     86.017907 | Gareth Monger                                                                                                                                                         |
| 825 |    516.219575 |    418.771121 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 826 |    850.516788 |    405.171147 | Becky Barnes                                                                                                                                                          |
| 827 |    319.495334 |     14.204702 | Matt Crook                                                                                                                                                            |
| 828 |    696.020476 |    547.095947 | Steven Traver                                                                                                                                                         |
| 829 |    225.152700 |    723.575951 | Mike Hanson                                                                                                                                                           |
| 830 |    575.412278 |    116.049272 | NA                                                                                                                                                                    |
| 831 |    322.546756 |    573.301959 | Gareth Monger                                                                                                                                                         |
| 832 |    456.208312 |     74.664695 | Steven Traver                                                                                                                                                         |
| 833 |    889.988299 |    127.038048 | T. Michael Keesey                                                                                                                                                     |
| 834 |    422.005307 |    561.617918 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 835 |    565.922469 |    109.573655 | Emily Willoughby                                                                                                                                                      |
| 836 |    246.351381 |     59.935909 | NA                                                                                                                                                                    |
| 837 |    331.592848 |    696.721522 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 838 |     96.249343 |    210.596077 | Mo Hassan                                                                                                                                                             |
| 839 |    608.057518 |    308.850424 | Margot Michaud                                                                                                                                                        |
| 840 |    740.705795 |    776.576436 | NA                                                                                                                                                                    |
| 841 |    282.608166 |    231.219370 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 842 |    663.796178 |     84.113754 | Gareth Monger                                                                                                                                                         |
| 843 |    599.399978 |    269.416580 | Qiang Ou                                                                                                                                                              |
| 844 |    995.148685 |    511.076371 | NA                                                                                                                                                                    |
| 845 |    466.934944 |     73.701195 | Gareth Monger                                                                                                                                                         |
| 846 |    858.026958 |    162.702830 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 847 |    891.684477 |    106.213689 | Zimices                                                                                                                                                               |
| 848 |    592.075275 |    792.173653 | Alexandre Vong                                                                                                                                                        |
| 849 |    993.219000 |     71.889388 | Michelle Site                                                                                                                                                         |
| 850 |    241.440188 |    775.498238 | Jakovche                                                                                                                                                              |
| 851 |     42.128560 |    430.225722 | Margot Michaud                                                                                                                                                        |
| 852 |    218.984838 |    754.458504 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 853 |    492.151482 |    176.588346 | Steven Traver                                                                                                                                                         |
| 854 |    243.484276 |    620.650573 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 855 |     33.686862 |    633.057150 | Matt Crook                                                                                                                                                            |
| 856 |    729.732894 |     21.063501 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 857 |    750.623144 |     37.999456 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 858 |    783.118797 |    308.606060 | Zimices                                                                                                                                                               |
| 859 |     93.975194 |    764.485057 | wsnaccad                                                                                                                                                              |
| 860 |    861.790387 |    747.872135 | Mathilde Cordellier                                                                                                                                                   |
| 861 |    303.996559 |    687.045359 | Chris huh                                                                                                                                                             |
| 862 |    634.348787 |    129.849103 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 863 |    170.851453 |    545.013278 | Gareth Monger                                                                                                                                                         |
| 864 |    387.203380 |    328.615687 | Zimices                                                                                                                                                               |
| 865 |    132.438188 |    392.388924 | Yan Wong                                                                                                                                                              |
| 866 |    140.093055 |    245.400169 | NA                                                                                                                                                                    |
| 867 |    257.543009 |    469.436241 | Robert Gay                                                                                                                                                            |
| 868 |    766.970585 |    382.438653 | Chloé Schmidt                                                                                                                                                         |
| 869 |    989.236391 |    552.179859 | Zimices                                                                                                                                                               |
| 870 |    633.590220 |     22.579517 | Matt Crook                                                                                                                                                            |
| 871 |    747.128460 |    760.372915 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 872 |    157.933577 |    271.888370 | Sarah Werning                                                                                                                                                         |
| 873 |    510.451203 |    306.174446 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 874 |    324.939529 |    650.510564 | Gareth Monger                                                                                                                                                         |
| 875 |    240.381180 |    476.601106 | Ferran Sayol                                                                                                                                                          |
| 876 |    431.613914 |    157.492452 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 877 |    961.736349 |    792.308388 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 878 |    617.685282 |    782.647454 | Margot Michaud                                                                                                                                                        |
| 879 |    336.029038 |    757.775083 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 880 |    909.045396 |    240.858368 | T. Michael Keesey                                                                                                                                                     |
| 881 |    483.901828 |    572.617230 | Gareth Monger                                                                                                                                                         |
| 882 |    370.762913 |    149.410464 | Roberto Díaz Sibaja                                                                                                                                                   |
| 883 |    887.637232 |    775.972218 | Zimices                                                                                                                                                               |
| 884 |    188.431337 |    601.944864 | Scott Hartman                                                                                                                                                         |
| 885 |    760.144214 |    634.688114 | Zimices                                                                                                                                                               |
| 886 |    998.345267 |    309.860440 | Mark Miller                                                                                                                                                           |
| 887 |   1005.003760 |    398.004665 | Scott Hartman                                                                                                                                                         |
| 888 |    309.675997 |    571.022417 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 889 |    943.023900 |     97.165353 | Kamil S. Jaron                                                                                                                                                        |
| 890 |    967.755079 |    398.773973 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 891 |    114.604075 |    580.845031 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 892 |    118.053087 |    493.831995 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 893 |     12.521358 |    149.413540 | NA                                                                                                                                                                    |
| 894 |    579.022765 |    283.247314 | John Conway                                                                                                                                                           |
| 895 |    407.579015 |    672.738791 | Liftarn                                                                                                                                                               |
| 896 |    777.530503 |    175.625224 | Margot Michaud                                                                                                                                                        |
| 897 |    354.246000 |    786.617899 | Anthony Caravaggi                                                                                                                                                     |
| 898 |    965.895562 |    130.999100 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 899 |    170.061956 |    704.250307 | Christoph Schomburg                                                                                                                                                   |
| 900 |    427.886727 |     62.137052 | Jagged Fang Designs                                                                                                                                                   |
| 901 |    512.589036 |    622.322363 | Shyamal                                                                                                                                                               |
| 902 |    308.971532 |    595.817622 | NA                                                                                                                                                                    |
| 903 |    585.944665 |     27.706989 | Vanessa Guerra                                                                                                                                                        |
| 904 |    685.429948 |     91.136201 | Ingo Braasch                                                                                                                                                          |
| 905 |     28.985994 |    625.111519 | Gareth Monger                                                                                                                                                         |
| 906 |    808.629601 |    262.715850 | Mathieu Basille                                                                                                                                                       |
| 907 |    712.611750 |     27.366165 | Scott Hartman                                                                                                                                                         |
| 908 |    596.811315 |    487.602546 | Steven Traver                                                                                                                                                         |
| 909 |    741.370079 |    209.065904 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                       |
| 910 |    548.434191 |    401.441494 | Pete Buchholz                                                                                                                                                         |
| 911 |    904.644260 |    400.287838 | Scott Hartman                                                                                                                                                         |
| 912 |    883.774577 |    611.092579 | Xavier Giroux-Bougard                                                                                                                                                 |
| 913 |    263.184533 |    350.669832 | C. Camilo Julián-Caballero                                                                                                                                            |
| 914 |   1008.759402 |     40.013532 | Smokeybjb                                                                                                                                                             |
| 915 |    972.541835 |    506.102020 | Sarah Werning                                                                                                                                                         |
| 916 |    775.892180 |     80.721402 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 917 |    665.039453 |    743.327545 | Gareth Monger                                                                                                                                                         |
